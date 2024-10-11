// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';
import '../../../widgets/download_status_icon.dart';

class ChapterListTile extends StatelessWidget {
  const ChapterListTile({
    super.key,
    required this.manga,
    required this.chapter,
    required this.updateData,
    required this.toggleSelect,
    required this.dateFormatPref,
    this.canTapSelect = false,
    this.isSelected = false,
  });
  final Manga manga;
  final Chapter chapter;
  final AsyncCallback updateData;
  final ValueChanged<Chapter> toggleSelect;
  final DateFormatEnum dateFormatPref;
  final bool canTapSelect;
  final bool isSelected;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () => toggleSelect(chapter),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 6.0),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (chapter.bookmarked.ifNull()) ...[
              Icon(
                Icons.bookmark,
                color: chapter.read.ifNull() ? Colors.grey : context.iconColor,
                size: 20,
              ),
              KSizedBox.w4.size,
            ],
            Expanded(
              child: Text(
                chapter.name ??
                    context.l10n!.chapterNumber(chapter.chapterNumber ?? 0),
                style: TextStyle(
                  color: chapter.read.ifNull() ? Colors.grey : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: chapter.uploadDate != null
            ? Row(
                children: [
                  Text(
                    chapter.uploadDate!
                        .toLocalizedDaysAgo(dateFormatPref, context),
                    style: TextStyle(
                      color: chapter.read.ifNull() ? Colors.grey : null,
                    ),
                  ),
                  if (!chapter.read.ifNull() &&
                      (chapter.lastPageRead).ifNullOrNegative() != 0)
                    Text(
                      " • ${context.l10n!.page(chapter.lastPageRead.ifNullOrNegative() + 1)}",
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (chapter.scanlator.isNotBlank == true)
                    Expanded(
                      child: Text(
                        " • ${chapter.scanlator}",
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              )
            : null,
        leading: canTapSelect
            ? (isSelected
                ? const Icon(Icons.check_circle)
                : const Icon(Icons.radio_button_unchecked))
            : null,
        trailing:
            (manga.sourceId != "0" && chapter.index != null && manga.id != null)
                ? DownloadStatusIcon(
                    updateData: updateData,
                    chapter: chapter,
                    mangaId: manga.id!,
                    isDownloaded: chapter.downloaded.ifNull(),
                  )
                : null,
        selectedColor: context.theme.colorScheme.onSurface,
        selectedTileColor:
            context.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        selected: isSelected,
        onTap: canTapSelect
            ? () => toggleSelect(chapter)
            : () => context.push(
                  Routes.getReader(
                    "${manga.id}",
                    "${chapter.index}",
                  ),
                ),
        onLongPress: () => toggleSelect(chapter),
      ),
    );
  }
}
