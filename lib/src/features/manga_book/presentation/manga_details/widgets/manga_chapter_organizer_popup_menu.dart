// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../controller/manga_chapter_controller.dart';
import '../controller/manga_details_controller.dart';

class MangaChapterOrganizerPopupMenu extends HookConsumerWidget {
  const MangaChapterOrganizerPopupMenu({
    super.key,
    required this.mangaId,
  });

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // unread filter
    final filterUnreadWithMangaIdProvider =
        mangaChapterFilterUnreadWithMangaIdProvider(mangaId: mangaId);
    final filterUnreadWithMangaId = ref.watch(filterUnreadWithMangaIdProvider);
    final filterUnreadGlobal = ref.watch(mangaChapterFilterUnreadProvider);

    // bookmarked filter
    final filterBookmarkedWithMangaIdProvider =
        mangaChapterFilterBookmarkedWithMangaIdProvider(mangaId: mangaId);
    final filterBookmarkedWithMangaId =
        ref.watch(filterBookmarkedWithMangaIdProvider);
    final filterBookmarkedGlobal =
        ref.watch(mangaChapterFilterBookmarkedProvider);

    // downloaded filter
    final filterDownloadedWithMangaIdProvider =
        mangaChapterFilterDownloadedWithMangaIdProvider(mangaId: mangaId);
    final filterDownloadedWithMangaId =
        ref.watch(filterDownloadedWithMangaIdProvider);
    final filterDownloadedGlobal =
        ref.watch(mangaChapterFilterDownloadedProvider);

    // sort by
    final globalSortedBy = ref.watch(mangaChapterSortProvider);
    final mangaIdSortedByProvider =
        mangaChapterSortWithMangaIdProvider(mangaId: mangaId);
    final mangaSortedBy = ref.watch(mangaIdSortedByProvider);

    // sort direction
    final globalSortedDirection = ref.watch(mangaChapterSortDirectionProvider);
    final mangaIdSortedDirectionProvider =
        mangaChapterSortDirectionWithMangaIdProvider(mangaId: mangaId);
    final mangaSortedDirection = ref.watch(mangaIdSortedDirectionProvider);

    final showSetAsDefault = filterUnreadWithMangaId != filterUnreadGlobal ||
        filterBookmarkedWithMangaId != filterBookmarkedGlobal ||
        filterDownloadedWithMangaId != filterDownloadedGlobal ||
        globalSortedBy != mangaSortedBy ||
        globalSortedDirection != mangaSortedDirection;

    return PopupMenuButton(
      shape: RoundedRectangleBorder(
        borderRadius: KBorderRadius.r16.radius,
      ),
      icon: Icon(
        Icons.more_vert_outlined,
        color: showSetAsDefault ? null : Colors.grey,
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: showSetAsDefault,
          onTap: () {
            ref
                .read(mangaChapterFilterUnreadProvider.notifier)
                .update(filterUnreadWithMangaId);
            ref
                .read(mangaChapterFilterBookmarkedProvider.notifier)
                .update(filterBookmarkedWithMangaId);
            ref
                .read(mangaChapterFilterDownloadedProvider.notifier)
                .update(filterDownloadedWithMangaId);
            ref.read(mangaChapterSortProvider.notifier).update(mangaSortedBy);
            ref
                .read(mangaChapterSortDirectionProvider.notifier)
                .update(mangaSortedDirection);

            ref
                .read(filterUnreadWithMangaIdProvider.notifier)
                .update(filterUnreadWithMangaId);
            ref
                .read(filterBookmarkedWithMangaIdProvider.notifier)
                .update(filterBookmarkedWithMangaId);
            ref
                .read(filterDownloadedWithMangaIdProvider.notifier)
                .update(filterDownloadedWithMangaId);
            ref.read(mangaIdSortedByProvider.notifier).update(mangaSortedBy);
            ref
                .read(mangaIdSortedDirectionProvider.notifier)
                .update(mangaSortedDirection);
          },
          child: Text(context.l10n!.set_as_default),
        ),
        PopupMenuItem(
          enabled: showSetAsDefault,
          onTap: () {
            ref
                .read(filterUnreadWithMangaIdProvider.notifier)
                .update(filterUnreadGlobal);
            ref
                .read(filterBookmarkedWithMangaIdProvider.notifier)
                .update(filterBookmarkedGlobal);
            ref
                .read(filterDownloadedWithMangaIdProvider.notifier)
                .update(filterDownloadedGlobal);
            ref.read(mangaIdSortedByProvider.notifier).update(globalSortedBy);
            ref
                .read(mangaIdSortedDirectionProvider.notifier)
                .update(globalSortedDirection);
          },
          child: Text(context.l10n!.reset_to_default),
        ),
      ],
    );
  }
}
