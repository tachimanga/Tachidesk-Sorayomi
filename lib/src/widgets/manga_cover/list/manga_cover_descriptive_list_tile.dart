// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../constants/app_sizes.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';

import '../../../utils/extensions/custom_extensions.dart';
import '../grid/manga_cover_grid_tile.dart';
import '../widgets/manga_badges.dart';
import '../widgets/manga_chips.dart';

class MangaCoverDescriptiveListTile extends StatelessWidget {
  const MangaCoverDescriptiveListTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.onLongPress,
    this.onTitleClicked,
    this.showBadges = true,
    this.showCountBadges = true,
    this.showLastReadChapter = false,
    this.popupItems,
  });
  final Manga manga;
  final bool showBadges;
  final bool showCountBadges;
  final bool showLastReadChapter;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<String?>? onTitleClicked;
  final List<PopupMenuItem>? popupItems;
  @override
  Widget build(BuildContext context) {
    final sourceName =
        " • ${manga.source?.displayName ?? context.l10n!.unknownSource}";
    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 160,
              child: MangaCoverGridTile(
                manga: manga,
                showBadges: false,
                showTitle: false,
                showDarkOverlay: false,
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onTitleClicked != null
                          ? () => onTitleClicked!(manga.title)
                          : null,
                      child: Text(
                        (manga.title ?? context.l10n!.unknownManga),
                        style: context.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        semanticsLabel: manga.title,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        manga.author ?? context.l10n!.unknownAuthor,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (manga.status != null) ...[
                          Icon(
                            manga.status!.icon,
                            size: 16,
                            color: context.textTheme.bodySmall?.color,
                          ),
                          Text(
                            " ${manga.status!.toLocale(context)}",
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                        if (manga.source?.displayName != null)
                          Text(
                            sourceName,
                            style: context.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (showLastReadChapter) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Text(
                          manga.lastChapterRead?.name ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          manga.lastReadAt.toDaysAgoFromSeconds ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
                      ),
                    ],
                    if (showBadges)
                      context.isTablet
                          ? MangaChipsRow(
                              manga: manga,
                              showCountBadges: showCountBadges,
                            )
                          : MangaBadgesRow(
                              padding: KEdgeInsets.v8.size,
                              manga: manga,
                              showCountBadges: showCountBadges,
                            ),
                    if (onTitleClicked != null) ...[
                      TextButton.icon(
                        onPressed: () {
                          onTitleClicked!(manga.title);
                        },
                        icon: const Icon(Icons.search),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: EdgeInsets.zero),
                        label: Text(context.l10n!.globalSearch),
                      )
                    ]
                  ],
                ),
              ),
            ),
            if (popupItems?.isNotEmpty == true) ...[
              PopupMenuButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: KBorderRadius.r16.radius,
                  ),
                  itemBuilder: (context) => popupItems!)
            ],
          ],
        ),
      ),
    );
  }
}
