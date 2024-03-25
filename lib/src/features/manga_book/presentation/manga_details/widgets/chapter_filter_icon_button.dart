// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../widgets/highlighted_container.dart';
import '../controller/manga_details_controller.dart';

class ChapterFilterIconButton extends HookConsumerWidget {
  const ChapterFilterIconButton(
      {super.key, required this.mangaId, required this.icon});

  final String mangaId;
  final Widget icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterFilterUnread = ref.watch(mangaChapterFilterUnreadProvider);
    final chapterFilterDownloaded =
        ref.watch(mangaChapterFilterDownloadedProvider);
    final chapterFilterBookmark =
        ref.watch(mangaChapterFilterBookmarkedProvider);
    final chapterFilterScanlators =
        ref.watch(mangaChapterFilterScanlatorProvider(mangaId: mangaId));

    return HighlightedContainer(
      highlighted: chapterFilterUnread != null ||
          chapterFilterDownloaded != null ||
          chapterFilterBookmark != null ||
          chapterFilterScanlators.isNotEmpty,
      child: icon,
    );
  }
}
