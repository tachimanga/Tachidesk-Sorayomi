// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../domain/manga/manga_model.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/manga_cover_util.dart';
import '../../../../../widgets/manga_cover/widgets/manga_badges.dart';
import '../../../../../widgets/server_image.dart';

class UpdateSummaryMangaListTile extends StatelessWidget {
  const UpdateSummaryMangaListTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.updateErrorMessage,
  });

  final Manga manga;
  final VoidCallback? onPressed;
  final String? updateErrorMessage;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          SizedBox(width: 8),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (manga.title ?? manga.author ?? ""),
                    overflow: TextOverflow.ellipsis,
                    maxLines: updateErrorMessage != null ? 1 : 2,
                  ),
                  if (updateErrorMessage != null) ...[
                    Text(
                      updateErrorMessage ?? "",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: context.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ]
                ],
              ),
            ),
          ),
          MangaBadgesRow(manga: manga, showCountBadges: true),
          SizedBox(width: 4),
        ],
      ),
    );
  }
}
