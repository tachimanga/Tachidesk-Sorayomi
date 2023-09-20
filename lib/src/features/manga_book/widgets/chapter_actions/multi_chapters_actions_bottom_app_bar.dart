// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/chapter_batch/chapter_batch_model.dart';
import '../../domain/chapter_patch/chapter_put_model.dart';
import 'multi_chapters_action_icon.dart';
import 'single_chapter_action_icon.dart';

class MultiChaptersActionsBottomAppBar extends HookConsumerWidget {
  const MultiChaptersActionsBottomAppBar({
    super.key,
    required this.selectedChapters,
    required this.afterOptionSelected,
  });

  final ValueNotifier<Map<int, Chapter>> selectedChapters;
  final AsyncCallback afterOptionSelected;

  List<int> get chapterList => selectedChapters.value.keys.toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    refresh([bool triggerAfterOption = true]) async {
      selectedChapters.value = <int, Chapter>{};
      if (triggerAfterOption) await afterOptionSelected();
    }

    final selectedList = selectedChapters.value.values;
    final safeAreaBottom = MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, safeAreaBottom > 0 ? max(0, safeAreaBottom - 14) : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (selectedList.any((e) => e.bookmarked.ifNull()))
            MultiChaptersActionIcon(
              icon: Icons.bookmark_remove_sharp,
              chapterList: chapterList,
              change: ChapterChange(isBookmarked: false),
              refresh: refresh,
            ),
          if (selectedList.any((e) => !(e.bookmarked.ifNull())))
            MultiChaptersActionIcon(
              icon: Icons.bookmark_add_sharp,
              chapterList: chapterList,
              change: ChapterChange(isBookmarked: true),
              refresh: refresh,
            ),
          if (selectedList.isSingletonList)
            SingleChapterActionIcon(
              chapterIndex:
                  "${selectedChapters.value[chapterList.first]?.index}",
              mangaId: "${selectedChapters.value[chapterList.first]?.mangaId}",
              imageIcon: ImageIcon(
                Assets.icons.previousDone.provider(),
                color: context.theme.cardTheme.color,
              ),
              chapterPut: ChapterPut(markPrevRead: true),
              refresh: refresh,
            ),
          if (selectedList.any((e) => !(e.read.ifNull())))
            MultiChaptersActionIcon(
              icon: Icons.done_all_sharp,
              chapterList: chapterList,
              change: ChapterChange(isRead: true, lastPageRead: 0),
              refresh: refresh,
            ),
          if (selectedList.any((e) => e.read.ifNull()))
            MultiChaptersActionIcon(
              icon: Icons.remove_done_sharp,
              chapterList: chapterList,
              change: ChapterChange(isRead: false),
              refresh: refresh,
            ),
          if (selectedList.any((e) => !(e.downloaded.ifNull())))
            MultiChaptersActionIcon(
              icon: Icons.download_sharp,
              chapterList: <int>[
                for (var e in selectedList)
                  if (!(e.downloaded.ifNull(true))) (e.id!)
              ],
              refresh: refresh,
            ),
          if (selectedList.any((e) => e.downloaded.ifNull()))
            MultiChaptersActionIcon(
              icon: Icons.delete_sharp,
              chapterList: chapterList,
              change: ChapterChange(delete: true),
              refresh: refresh,
            ),
        ],
      ),
    );
  }
}
