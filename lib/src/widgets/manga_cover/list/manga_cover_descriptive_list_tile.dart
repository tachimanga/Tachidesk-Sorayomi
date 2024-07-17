// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/enum.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';

import '../../../features/manga_book/presentation/manga_details/manga_cover_screen.dart';
import '../../../features/settings/presentation/appearance/controller/date_format_controller.dart';
import '../../../routes/router_config.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../grid/manga_cover_grid_tile.dart';
import '../widgets/clipboard_wrapper.dart';
import '../widgets/manga_badges.dart';
import '../widgets/manga_chips.dart';

class MangaCoverDescriptiveListTile extends ConsumerWidget {
  const MangaCoverDescriptiveListTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.onLongPress,
    this.onTitleClicked,
    this.showBadges = true,
    this.showCountBadges = true,
    this.showLastReadChapter = false,
    this.enableCoverPopup = false,
    this.enableTitleCopy = false,
    this.enableSourceEntrance = false,
    this.popupItems,
  });
  final Manga manga;
  final bool showBadges;
  final bool showCountBadges;
  final bool showLastReadChapter;
  final bool enableCoverPopup;
  final bool enableTitleCopy;
  final bool enableSourceEntrance;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<String?>? onTitleClicked;
  final List<PopupMenuItem>? popupItems;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;
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
                decodeWidth: kMangaCoverDecodeWidth,
                manga: manga,
                showBadges: false,
                showTitle: false,
                showDarkOverlay: false,
                onPressed:
                    enableCoverPopup ? () => openMangaCover(context) : null,
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
                    ClipboardWrapper(
                      text: enableTitleCopy ? manga.title : null,
                      onLongPressed: onTitleClicked != null
                          ? () {
                              onTitleClicked!(manga.title);
                            }
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
                      child: ClipboardWrapper(
                        text: enableTitleCopy ? manga.author : null,
                        onLongPressed: onTitleClicked != null
                            ? () {
                                onTitleClicked!(manga.author);
                              }
                            : null,
                        child: Text(
                          manga.author ?? context.l10n!.unknownAuthor,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
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
                          InkWell(
                            onTap: enableSourceEntrance ? () {
                              final source = manga.source;
                              if (source?.id == null) return;
                              context.push(Routes.getSourceManga(
                                source!.id!,
                                SourceType.popular,
                              ));
                            } : null,
                            child: Text(
                              sourceName,
                              style: context.textTheme.bodySmall,
                            ),
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
                          manga.lastReadAt.toLocalizedDaysAgoFromSeconds(
                            dateFormatPref,
                            context,
                          ),
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

  void openMangaCover(BuildContext context) {
    if (manga.id != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          fullscreenDialog: true,
          opaque: false,
          pageBuilder: (context, _, __) => MangaCoverScreen(
            manga: manga,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      );
    }
  }
}
