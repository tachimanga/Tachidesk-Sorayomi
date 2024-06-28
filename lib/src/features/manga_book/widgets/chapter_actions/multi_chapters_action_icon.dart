// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../data/downloads/downloads_repository.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter_batch/chapter_batch_model.dart';
import '../../presentation/downloads/widgets/download_reward_ad_dialog.dart';

class MultiChaptersActionIcon extends ConsumerWidget {
  const MultiChaptersActionIcon({
    required this.icon,
    required this.chapterList,
    this.change,
    required this.refresh,
    super.key,
  });
  final List<int> chapterList;
  final ChapterChange? change;
  final AsyncValueSetter<bool> refresh;
  final IconData icon;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    return IconButton(
      icon: Icon(icon),
      onPressed: () async {
        if (change == null) {
          (await AsyncValue.guard(
            () async {
              await showAdDialogIfNeeded(
                context: context,
                ref: ref,
                chaptersCount: chapterList.length,
                onPass: () async {
                  await ref
                      .read(downloadsRepositoryProvider)
                      .addChaptersBatchToDownloadQueue(chapterList);
                },
              );
            },
          ))
              .showToastOnError(toast);
        } else {
          (await AsyncValue.guard(
            () => ref.read(mangaBookRepositoryProvider).modifyBulkChapters(
                  batch: ChapterBatch(
                    chapterIds: chapterList,
                    change: change,
                  ),
                ),
          ))
              .showToastOnError(toast);
        }
        await refresh(change != null);
      },
    );
  }
}
