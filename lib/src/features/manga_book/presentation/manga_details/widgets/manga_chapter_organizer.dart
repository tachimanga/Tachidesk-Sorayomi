// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/colored_safe_area.dart';
import 'manga_chapter_filter.dart';
import 'manga_chapter_organizer_popup_menu.dart';
import 'manga_chapter_sort.dart';

class MangaChapterOrganizer extends StatelessWidget {
  const MangaChapterOrganizer({super.key, required this.mangaId});
  final String mangaId;
  @override
  Widget build(BuildContext context) {
    return ColoredSafeArea(
        child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: TabBarWithButton(
          tabBar: TabBar(
            tabs: [
              Tab(text: context.l10n!.filter),
              Tab(text: context.l10n!.sort),
            ],
          ),
          button: MangaChapterOrganizerPopupMenu(mangaId: mangaId),
        ),
        body: TabBarView(
          children: [
            MangaChapterFilter(mangaId: mangaId),
            MangaChapterSort(mangaId: mangaId),
          ],
        ),
      ),
    ));
  }
}

class TabBarWithButton extends StatelessWidget implements PreferredSizeWidget {
  const TabBarWithButton({
    super.key,
    required this.tabBar,
    required this.button,
  });

  final TabBar tabBar;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.topEnd,
      children: [
        tabBar,
        button,
      ],
    );
  }

  @override
  Size get preferredSize {
    return tabBar.preferredSize;
  }
}

void showMangaChapterOrganizer(
  BuildContext context,
  String mangaId,
) {
  if (context.isTablet) {
    Scaffold.of(context).openEndDrawer();
  } else {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: KBorderRadius.rT16.radius,
      ),
      clipBehavior: Clip.hardEdge,
      builder: (_) => MangaChapterOrganizer(
        mangaId: mangaId,
      ),
    );
  }
}
