// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../icons/icomoon_icons.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/manga_cover/grid/manga_cover_grid_tile.dart';
import '../../../../settings/presentation/appearance/controller/date_format_controller.dart';
import '../../../domain/manga/manga_model.dart';

const kHistoryMangaCoverHeight = 120.0;
const kHistoryMangaCoverWidth = kHistoryMangaCoverHeight * 0.75;

class HistoryDescriptiveListTile extends ConsumerWidget {
  const HistoryDescriptiveListTile({
    super.key,
    required this.manga,
    this.onPressed,
    this.onLongPress,
    this.popupItems,
  });

  final Manga manga;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final List<PopupMenuItem>? popupItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;
    final readTimeString = manga.readDuration.toLocalizedReadTime(context);

    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: kHistoryMangaCoverWidth,
              height: kHistoryMangaCoverHeight,
              child: MangaCoverGridTile(
                decodeWidth: kMangaCoverDecodeWidth,
                manga: manga,
                showBadges: false,
                showTitle: false,
                showDarkOverlay: false,
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
            Expanded(
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: kHistoryMangaCoverHeight),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (manga.title ?? context.l10n!.unknownManga),
                      style:
                          context.textTheme.titleMedium?.copyWith(height: 1.25),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      semanticsLabel: manga.title,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manga.lastChapterRead?.name ??
                          manga.lastChapterReadName ??
                          "",
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    if (readTimeString != null) ...[
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
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: context.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          manga.lastReadAt.toLocalizedDaysAgoFromSeconds(
                            dateFormatPref,
                            context,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (popupItems?.isNotEmpty == true) ...[
              PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.r16.radius,
                ),
                itemBuilder: (context) => popupItems!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
