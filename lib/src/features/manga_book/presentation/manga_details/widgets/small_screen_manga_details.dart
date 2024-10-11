// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../../widgets/scrollbar_behavior.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';
import 'chapter_filter_icon_button.dart';
import 'chapter_list_tile.dart';
import 'manga_chapter_list_header.dart';
import 'manga_chapter_organizer.dart';
import 'manga_description.dart';
import 'manga_details_no_chapter_view.dart';

class SmallScreenMangaDetails extends HookConsumerWidget {
  const SmallScreenMangaDetails({
    super.key,
    required this.chapterList,
    required this.manga,
    required this.selectedChapters,
    required this.mangaId,
    required this.onRefresh,
    required this.onDescriptionRefresh,
    required this.onListRefresh,
    required this.dateFormatPref,
    required this.animationController,
    required this.showCoverRefreshIndicator,
    required this.refreshIndicatorKey,
  });
  final String mangaId;
  final Manga manga;
  final AsyncValueSetter<bool> onRefresh;
  final ValueNotifier<Map<int, Chapter>> selectedChapters;
  final AsyncValue<List<Chapter>?> chapterList;
  final AsyncValueSetter<bool> onListRefresh;
  final AsyncValueSetter<bool> onDescriptionRefresh;
  final DateFormatEnum dateFormatPref;
  final AnimationController animationController;
  final bool showCoverRefreshIndicator;
  final ObjectRef<GlobalKey<RefreshIndicatorState>> refreshIndicatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredChapterList = chapterList.valueOrNull;

    EdgeInsets padding = MediaQuery.paddingOf(context);
    // MangaCoverDescriptiveListTile padding * 2 + cover.height
    final backgroundImageHeight = padding.top + 8 * 2 + 160;

    return RefreshIndicator(
      key: refreshIndicatorKey.value,
      edgeOffset: kToolbarHeight,
      onRefresh: () => onRefresh(true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.axis == Axis.vertical) {
            animationController
                .animateTo(scrollInfo.metrics.pixels / backgroundImageHeight);
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                child: MangaDescription(
                  manga: manga,
                  refresh: () => onDescriptionRefresh(false),
                  enableStartReading: selectedChapters.value.isEmpty,
                  showCoverRefreshIndicator: showCoverRefreshIndicator,
                  backgroundImageHeight: backgroundImageHeight,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: MangaChapterListHeader(
                mangaId: mangaId,
                chapterCount: filteredChapterList?.length ?? 0,
              ),
            ),
            chapterList.showUiWhenData(
              context,
              (data) {
                if (data.isNotBlank) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ChapterListTile(
                        key: ValueKey("${filteredChapterList[index].id}"),
                        manga: manga,
                        chapter: filteredChapterList[index],
                        updateData: () => onRefresh(false),
                        isSelected: selectedChapters.value
                            .containsKey(filteredChapterList[index].id),
                        canTapSelect: selectedChapters.value.isNotEmpty,
                        toggleSelect: (Chapter val) {
                          if ((val.id).isNull) return;
                          selectedChapters.value =
                              selectedChapters.value.toggleKey(val.id!, val);
                        },
                        dateFormatPref: dateFormatPref,
                      ),
                      childCount: filteredChapterList!.length,
                    ),
                  );
                } else {
                  return SliverToBoxAdapter(
                    child: MangaDetailsNoChapterErrorView(
                        manga: manga, refresh: () => onListRefresh(true)),
                  );
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
              wrapper: (child) => SliverToBoxAdapter(
                child: SizedBox(
                  height: context.height * .5,
                  child: child,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: ListTile()),
          ],
        ),
      ),
    );
  }
}
