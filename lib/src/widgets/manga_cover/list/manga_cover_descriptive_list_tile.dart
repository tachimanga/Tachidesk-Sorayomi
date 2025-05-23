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
import '../../../features/browse_center/domain/browse/browse_model.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';

import '../../../features/manga_book/presentation/manga_details/manga_cover_screen.dart';
import '../../../features/settings/presentation/appearance/controller/date_format_controller.dart';
import '../../../icons/icomoon_icons.dart';
import '../../../routes/router_config.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/launch_url_in_web.dart';
import '../../async_buttons/async_ink_well.dart';
import '../../custom_circular_progress_indicator.dart';
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
    this.showRefreshIndicator = false,
    this.enableCoverPopup = false,
    this.enableTitleCopy = false,
    this.enableSourceEntrance = false,
    this.showSourceUrl = false,
    this.showReadDuration = false,
    this.popupItems,
    this.selected = false,
  });

  final Manga manga;
  final bool showBadges;
  final bool showCountBadges;
  final bool showLastReadChapter;
  final bool showRefreshIndicator;
  final bool enableCoverPopup;
  final bool enableTitleCopy;
  final bool enableSourceEntrance;
  final bool showSourceUrl;
  final bool showReadDuration;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<String?>? onTitleClicked;
  final List<PopupMenuItem>? popupItems;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;
    final sourceName =
        " • ${manga.source?.displayName ?? context.l10n!.unknownSource}";
    final readTimeString = showReadDuration
        ? manga.readDuration.toLocalizedReadTime(context)
        : null;
    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: selected
            ? context.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: AlignmentDirectional.topEnd,
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed:
                        enableCoverPopup ? () => openMangaCover(context) : null,
                  ),
                ),
                if (showRefreshIndicator) ...[
                  MiniCircularProgressIndicator(padding: KEdgeInsets.a16.size),
                ],
              ],
            ),
            Expanded(
              flex: 3,
              child: Container(
                constraints: BoxConstraints(minHeight: 160),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
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
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (manga.status != null) ...[
                          Icon(
                            manga.status!.icon,
                            size: 16,
                            color: context.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            manga.status!.toLocale(context),
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                        if (manga.source?.displayName != null)
                          InkWell(
                            onTap: enableSourceEntrance
                                ? () {
                                    final source = manga.source;
                                    if (source?.id == null) return;
                                    context.push(Routes.getSourceManga(
                                      source!.id!,
                                      SourceType.popular,
                                    ));
                                  }
                                : null,
                            child: Text(
                              sourceName,
                              style: context.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                    if (showReadDuration && readTimeString != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icomoon.readTime2,
                            size: 16,
                            color: context.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            readTimeString,
                            style: context.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    if (showLastReadChapter) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Text(
                          manga.lastChapterRead?.name ??
                              manga.lastChapterReadName ??
                              "",
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
                    if (showSourceUrl && manga.realUrl.isNotBlank == true) ...[
                      Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                          child: AsyncInkWell(
                            onTap: () => launchUrlInWebView(
                              context,
                              ref,
                              UrlFetchInput.ofManga(manga.id),
                            ),
                            child: Text(
                              manga.realUrl ?? "",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade800,
                              ),
                            ),
                          )),
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
                          foregroundColor: context.isDarkMode
                              ? Colors.grey
                              : Colors.grey.shade600,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
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
          settings: const RouteSettings(name: "/manga-cover"),
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
