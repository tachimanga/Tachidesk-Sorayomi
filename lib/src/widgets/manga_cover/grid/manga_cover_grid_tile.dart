// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';
import '../../../features/settings/presentation/appearance/controller/theme_controller.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/manga_cover_util.dart';
import '../../server_image.dart';
import '../widgets/manga_badges.dart';

class MangaCoverGridTile extends ConsumerWidget {
  const MangaCoverGridTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.onLongPress,
    this.showTitle = true,
    this.showBadges = true,
    this.showCountBadges = false,
    this.showDarkOverlay = true,
    this.decodeWidth,
    this.decodeHeight,
    this.margin,
  });

  final Manga manga;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool showCountBadges;
  final bool showTitle;
  final bool showBadges;
  final bool showDarkOverlay;
  final int? decodeWidth;
  final int? decodeHeight;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeData = ref.watch(themeSchemeColorProvider);
    final canvasColor = appThemeData.dark.canvasColor;

    return InkResponse(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r12.radius),
        margin: margin,
        child: GridTile(
          header: showBadges
              ? MangaBadgesRow(manga: manga, showCountBadges: showCountBadges)
              : null,
          footer: showTitle
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    (manga.title ?? manga.author ?? ""),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: appThemeData.dark.textTheme.titleSmall,
                  ),
                )
              : null,
          child: manga.thumbnailUrl != null && manga.thumbnailUrl!.isNotEmpty
              ? Container(
                  foregroundDecoration: BoxDecoration(
                    boxShadow: showDarkOverlay
                        ? [
                            BoxShadow(
                                color:
                                    context.theme.canvasColor.withOpacity(.2))
                          ]
                        : null,
                    gradient: showTitle
                        ? LinearGradient(
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                            colors: [
                              canvasColor.withOpacity(0),
                              canvasColor.withOpacity(0.4),
                              canvasColor.withOpacity(0.9),
                            ],
                          )
                        : null,
                  ),
                  child: ServerImage(
                    imageUrl: manga.thumbnailUrl ?? "",
                    imageData: manga.thumbnailImg,
                    extInfo: CoverExtInfo.build(manga),
                    decodeWidth: decodeWidth,
                    decodeHeight: decodeHeight,
                  ),
                )
              : SizedBox(
                  height: context.height * .3,
                  child: Icon(
                    Icons.book_rounded,
                    color: Colors.grey,
                    size: context.height * .2,
                  ),
                ),
        ),
      ),
    );
  }
}
