// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import 'manga_chapter_sort_tile.dart';

class MangaChapterSort extends ConsumerWidget {
  const MangaChapterSort({super.key, required this.mangaId});
  final String mangaId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        const Divider(height: .5),
        MangaChapterSortTile(
          sortType: ChapterSort.source,
          mangaId: mangaId,
        ),
        MangaChapterSortTile(
          sortType: ChapterSort.fetchedDate,
          mangaId: mangaId,
        ),
      ],
    );
  }
}
