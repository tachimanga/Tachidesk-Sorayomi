// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as ftoast;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/highlighted_container.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../downloads/widgets/download_reward_ad_dialog.dart';
import '../controller/manga_details_controller.dart';

class MangaChapterDownloadButton extends HookConsumerWidget {
  const MangaChapterDownloadButton({super.key, required this.mangaId});

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final isAscSorted = ref.watch(mangaChapterSortDirectionProvider) ??
        DBKeys.chapterSortDirection.initial;
    final filteredList = ref
        .watch(mangaChapterListWithFilterProvider(mangaId: mangaId))
        .valueOrNull;
    final firstUnreadChapter = ref.watch(
      firstUnreadInFilteredChapterListProvider(mangaId: mangaId),
    );
    return PopupMenuButton(
      enabled: filteredList != null,
      shape: RoundedRectangleBorder(
        borderRadius: KBorderRadius.r16.radius,
      ),
      icon: const Icon(Icons.download_outlined),
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: () async {
            logEvent3("MANGA:DOWNLOAD:NEXT:1");
            final chapterIds = _buildNextChapterIds(
                isAscSorted, filteredList!, firstUnreadChapter, 1);
            await _downloadChapters(context, ref, toast, chapterIds);
          },
          child: Text(context.l10n!.download_next_n_chapter(1)),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("MANGA:DOWNLOAD:NEXT:5");
            final chapterIds = _buildNextChapterIds(
                isAscSorted, filteredList!, firstUnreadChapter, 5);
            await _downloadChapters(context, ref, toast, chapterIds);
          },
          child: Text(context.l10n!.download_next_n_chapter(5)),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("MANGA:DOWNLOAD:NEXT:10");
            final chapterIds = _buildNextChapterIds(
                isAscSorted, filteredList!, firstUnreadChapter, 10);
            await _downloadChapters(context, ref, toast, chapterIds);
          },
          child: Text(context.l10n!.download_next_n_chapter(10)),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("MANGA:DOWNLOAD:UNREAD_ALL");
            final chapterIds = filteredList!
                .where((e) =>
                    e.downloaded != true && e.id != null && e.read != true)
                .map((e) => e.id!)
                .toList();
            await _downloadChapters(context, ref, toast, chapterIds);
          },
          child: Text(context.l10n!.download_unread_chapters),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("MANGA:DOWNLOAD:ALL");
            final chapterIds = filteredList!
                .where((e) => e.downloaded != true && e.id != null)
                .map((e) => e.id!)
                .toList();
            await _downloadChapters(context, ref, toast, chapterIds);
          },
          child: Text(context.l10n!.download_all_chapters),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () {
            logEvent3("MANGA:DOWNLOAD:QUEUE");
            context.push(Routes.downloads);
          },
          child: Text(context.l10n!.download_queue),
        ),
      ],
    );
  }

  List<int> _buildNextChapterIds(bool isAscSorted, List<Chapter> filteredList,
      Chapter? firstUnreadChapter, int n) {
    final list = isAscSorted ? filteredList : filteredList.reversed;
    var find = false;
    final nextChapterList = <Chapter>[];
    for (final chapter in list) {
      if (chapter == firstUnreadChapter) {
        find = true;
      }
      if (find) {
        nextChapterList.add(chapter);
      }
    }

    final chapterIds = nextChapterList
        .where((e) => e.downloaded != true && e.id != null)
        .take(n)
        .map((e) => e.id!)
        .toList();
    return chapterIds;
  }

  Future<void> _downloadChapters(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    List<int> chapterIds,
  ) async {
    final tips = context.l10n!.add_download_tips(chapterIds.length);
    (await AsyncValue.guard(() async {
      await showAdDialogIfNeeded(
        context: context,
        ref: ref,
        chaptersCount: chapterIds.length,
        onPass: () async {
          await ref
              .read(downloadsRepositoryProvider)
              .addChaptersBatchToDownloadQueue(chapterIds);
          if (context.mounted) {
            final toast2 = ref.watch(toastProvider(context));
            toast2.show(tips, gravity: ftoast.ToastGravity.CENTER);
          }
        },
      );
    }))
        .showToastOnError(toast);
  }
}
