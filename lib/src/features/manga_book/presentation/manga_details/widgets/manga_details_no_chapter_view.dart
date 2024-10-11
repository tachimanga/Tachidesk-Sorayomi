// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/common_error_widget.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/manga_book_repository.dart';
import '../controller/manga_chapter_controller.dart';
import '../controller/manga_details_controller.dart';

class MangaDetailsNoChapterErrorView extends ConsumerWidget {
  const MangaDetailsNoChapterErrorView(
      {super.key, required this.manga, required this.refresh});

  final Manga manga;
  final VoidCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterUnreadWithMangaIdProvider =
        mangaChapterFilterUnreadWithMangaIdProvider(mangaId: "${manga.id}");
    final chapterFilterUnread = ref.watch(filterUnreadWithMangaIdProvider);

    final filterDownloadedWithMangaIdProvider =
        mangaChapterFilterDownloadedWithMangaIdProvider(mangaId: "${manga.id}");
    final chapterFilterDownloaded =
        ref.watch(filterDownloadedWithMangaIdProvider);

    final filterBookmarkedWithMangaIdProvider =
        mangaChapterFilterBookmarkedWithMangaIdProvider(mangaId: "${manga.id}");
    final chapterFilterBookmark =
        ref.watch(filterBookmarkedWithMangaIdProvider);

    final chapterFilterScanlators =
        ref.watch(mangaChapterFilterScanlatorProvider(mangaId: "${manga.id}"));

    if (chapterFilterUnread != null ||
        chapterFilterDownloaded != null ||
        chapterFilterBookmark != null ||
        chapterFilterScanlators.isNotEmpty) {
      return Emoticons(
          text: context.l10n!.noChaptersFound,
          button: TextButton(
            onPressed: () {
              ref.read(mangaChapterFilterUnreadProvider.notifier).update(null);
              ref
                  .read(mangaChapterFilterDownloadedProvider.notifier)
                  .update(null);
              ref
                  .read(mangaChapterFilterBookmarkedProvider.notifier)
                  .update(null);

              ref.read(filterUnreadWithMangaIdProvider.notifier).update(null);
              ref
                  .read(filterBookmarkedWithMangaIdProvider.notifier)
                  .update(null);
              ref
                  .read(filterDownloadedWithMangaIdProvider.notifier)
                  .update(null);
              ref
                  .read(mangaChapterFilterScanlatorProvider(
                          mangaId: "${manga.id}")
                      .notifier)
                  .update([]);
            },
            child: Text(context.l10n!.reset_filters),
          ));
    }

    return CommonErrorWidget(
        refresh: refresh,
        src: "manga_details",
        webViewUrlProvider: () async {
          final url = manga.realUrl;
          if (url?.isNotEmpty == true) {
            return url;
          }
          return await ref
              .read(mangaBookRepositoryProvider)
              .getMangaRealUrl(mangaId: "${manga.id}");
        },
        error: context.l10n!.noChaptersFound);
  }
}
