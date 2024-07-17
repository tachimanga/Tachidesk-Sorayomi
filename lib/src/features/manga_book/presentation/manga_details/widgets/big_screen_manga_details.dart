// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/scrollbar_behavior.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';
import 'chapter_list_tile.dart';
import 'manga_description.dart';
import 'manga_details_no_chapter_view.dart';

class BigScreenMangaDetails extends ConsumerWidget {
  const BigScreenMangaDetails({
    super.key,
    required this.chapterList,
    required this.manga,
    required this.mangaId,
    required this.selectedChapters,
    required this.onListRefresh,
    required this.onRefresh,
    required this.onDescriptionRefresh,
    required this.dateFormatPref,
  });
  final Manga manga;
  final String mangaId;
  final AsyncValueSetter<bool> onListRefresh;
  final AsyncValueSetter<bool> onDescriptionRefresh;
  final AsyncValueSetter<bool> onRefresh;
  final ValueNotifier<Map<int, Chapter>> selectedChapters;
  final AsyncValue<List<Chapter>?> chapterList;
  final DateFormatEnum dateFormatPref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredChapterList = chapterList.valueOrNull;
    return RefreshIndicator(
      onRefresh: () => onRefresh(true),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: MangaDescription(
                manga: manga,
                refresh: () => onDescriptionRefresh(false),
                enableStartReading: selectedChapters.value.isEmpty,
              ),
            ),
          ),
          const VerticalDivider(width: 0),
          Expanded(
            child: ScrollConfiguration(behavior: ScrollbarBehavior(), child:
            chapterList.showUiWhenData(
              context,
              (data) {
                if (data.isNotBlank) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(context.l10n!.noOfChapters(
                          filteredChapterList?.length ?? 0,
                        )),
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            if (filteredChapterList.length == index) {
                              return const ListTile();
                            }
                            final key =
                                ValueKey("${filteredChapterList[index].id}");
                            final chapter = filteredChapterList[index];
                            return ChapterListTile(
                              key: key,
                              manga: manga,
                              chapter: chapter,
                              updateData: () => onListRefresh(false),
                              isSelected: selectedChapters.value
                                  .containsKey(chapter.id),
                              canTapSelect: selectedChapters.value.isNotEmpty,
                              toggleSelect: (Chapter val) {
                                if ((val.id).isNull) return;
                                selectedChapters.value = selectedChapters.value
                                    .toggleKey(val.id!, val);
                              },
                              dateFormatPref: dateFormatPref,
                            );
                          },
                          itemCount: filteredChapterList!.length + 1,
                        ),
                      ),
                    ],
                  );
                } else {
                  return MangaDetailsNoChapterErrorView(
                      manga: manga, refresh: () => onListRefresh(true));
                }
              },
              refresh: () => onRefresh(false),
              errorSource: "manga-details",
              webViewUrlProvider: () async {
                final url = manga.realUrl;
                if (url?.isNotEmpty == true) {
                  return url;
                }
                return await ref
                    .read(mangaBookRepositoryProvider)
                    .getMangaRealUrl(mangaId: mangaId);
              },
            ),
          ),
          ),
        ],
      ),
    );
  }
}
