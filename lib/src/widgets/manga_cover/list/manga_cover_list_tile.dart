// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../constants/app_sizes.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/manga_cover_util.dart';
import '../../server_image.dart';
import '../widgets/manga_badges.dart';

class MangaCoverListTile extends StatelessWidget {
  const MangaCoverListTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.onLongPress,
    this.showBadges = true,
    this.showCountBadges = false,
    this.selected = false,
  });

  final Manga manga;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool showCountBadges;
  final bool showBadges;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Row(
        children: [
          Padding(
            padding: KEdgeInsets.a8.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ServerImage(
                imageUrl: manga.thumbnailUrl ?? "",
                imageData: manga.thumbnailImg,
                extInfo: CoverExtInfo.build(manga),
                size: const Size.square(48),
                decodeWidth: 48,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: KEdgeInsets.h8.size,
              child: Text(
                (manga.title ?? manga.author ?? ""),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          if (showBadges)
            MangaBadgesRow(manga: manga, showCountBadges: showCountBadges),
        ],
      ),
    );
    return Container(
      color: selected
          ? context.isDarkMode
              ? Colors.grey.shade700
              : Colors.grey.shade300
          : null,
      child: tile,
    );
  }
}
