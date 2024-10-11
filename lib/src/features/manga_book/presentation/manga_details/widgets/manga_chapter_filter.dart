// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/custom_checkbox_list_tile.dart';
import '../../../../../widgets/tristate_checkbox_list_tile.dart';
import '../../../domain/manga/manga_model.dart';
import '../controller/manga_chapter_controller.dart';
import '../controller/manga_details_controller.dart';

class MangaChapterFilter extends ConsumerWidget {
  const MangaChapterFilter({super.key, required this.mangaId});
  final String mangaId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // unread filter
    final filterUnreadWithMangaIdProvider =
        mangaChapterFilterUnreadWithMangaIdProvider(mangaId: mangaId);
    final filterUnreadWithMangaId = ref.watch(filterUnreadWithMangaIdProvider);

    // bookmarked filter
    final filterBookmarkedWithMangaIdProvider =
        mangaChapterFilterBookmarkedWithMangaIdProvider(mangaId: mangaId);
    final filterBookmarkedWithMangaId =
        ref.watch(filterBookmarkedWithMangaIdProvider);

    // downloaded filter
    final filterDownloadedWithMangaIdProvider =
        mangaChapterFilterDownloadedWithMangaIdProvider(mangaId: mangaId);
    final filterDownloadedWithMangaId =
        ref.watch(filterDownloadedWithMangaIdProvider);

    // scanlator filter
    final scanlatorList =
        ref.watch(mangaScanlatorListProvider(mangaId: mangaId));
    final selectedScanlators =
        ref.watch(mangaChapterFilterScanlatorProvider(mangaId: mangaId));
    final selectedScanlatorSet = {...selectedScanlators};

    return ListView(
      children: [
        TriCheckboxListTile(
          title: Text(context.l10n!.unread),
          value: filterUnreadWithMangaId,
          tristate: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: context.theme.indicatorColor,
          onChanged: (value) {
            ref.read(filterUnreadWithMangaIdProvider.notifier).update(value);
          },
        ),
        TriCheckboxListTile(
          title: Text(context.l10n!.bookmarked),
          value: filterBookmarkedWithMangaId,
          tristate: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: context.theme.indicatorColor,
          onChanged: (value) {
            ref
                .read(filterBookmarkedWithMangaIdProvider.notifier)
                .update(value);
          },
        ),
        TriCheckboxListTile(
          title: Text(context.l10n!.downloaded),
          value: filterDownloadedWithMangaId,
          tristate: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: context.theme.indicatorColor,
          onChanged: (value) {
            ref
                .read(filterDownloadedWithMangaIdProvider.notifier)
                .update(value);
          },
        ),
        if (scanlatorList.isNotBlank && scanlatorList.length > 1) ...[
          ListTile(
            title: Text(
              context.l10n!.scanlators,
              style: context.textTheme.labelLarge,
            ),
            dense: true,
          ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(context.l10n!.allScanlators),
            value: selectedScanlatorSet.isEmpty,
            onChanged: (value) {
              if (value == true) {
                ref
                    .read(mangaChapterFilterScanlatorProvider(mangaId: mangaId)
                        .notifier)
                    .update([]);
              }
            },
          ),
          for (final scanlator in scanlatorList)
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(scanlator),
              value: selectedScanlatorSet.contains(scanlator),
              onChanged: (value) {
                if (value == true) {
                  selectedScanlatorSet.add(scanlator);
                } else {
                  selectedScanlatorSet.remove(scanlator);
                }
                ref
                    .read(mangaChapterFilterScanlatorProvider(mangaId: mangaId)
                        .notifier)
                    .update([...selectedScanlatorSet]);
              },
            ),
        ],
      ],
    );
  }
}
