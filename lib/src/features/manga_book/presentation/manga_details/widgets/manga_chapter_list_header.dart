// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/common_error_widget.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/manga_book_repository.dart';
import '../controller/manga_chapter_controller.dart';
import '../controller/manga_details_controller.dart';
import 'chapter_filter_icon_button.dart';
import 'manga_chapter_organizer.dart';

class MangaChapterListHeader extends ConsumerWidget {
  const MangaChapterListHeader({
    super.key,
    required this.mangaId,
    required this.chapterCount,
  });

  final String mangaId;
  final int chapterCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaIdSortedDirectionProvider =
        mangaChapterSortDirectionWithMangaIdProvider(mangaId: mangaId);
    final sortedDirection = ref.watch(mangaIdSortedDirectionProvider);

    return ListTile(
      title: Text(
        context.l10n!.noOfChapters(chapterCount),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              ref
                  .read(mangaIdSortedDirectionProvider.notifier)
                  .update(!(sortedDirection.ifNull()));
            },
            icon: Icon(
              sortedDirection.ifNull(true)
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
            ),
          ),
          ChapterFilterIconButton(
            mangaId: mangaId,
            icon: IconButton(
              onPressed: () => showMangaChapterOrganizer(context, mangaId),
              icon: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 6.0),
    );
  }
}
