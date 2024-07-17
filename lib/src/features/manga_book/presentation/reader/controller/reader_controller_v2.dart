// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/img/image_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';
import 'reader_setting_controller.dart';

part 'reader_controller_v2.g.dart';

@riverpod
class DownscaleImage extends _$DownscaleImage
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: "config.downscaleImage2",
        initial: true,
      );
}

class ReaderPageData {
  final int chapterIndex;
  final int pageIndex;
  final ImgData? imageData;
  final int? chapterId;

  ReaderPageData(
    this.chapterIndex,
    this.pageIndex,
    this.imageData,
    this.chapterId,
  );
}

class ReaderDoublePageData {
  final ReaderPageData first;
  final ReaderPageData? second;
  final bool singlePage;
  
  ReaderDoublePageData(this.first, this.second, this.singlePage);
}

class PageChangedData {
  final ReaderPageData currentPage;
  final bool flush;

  PageChangedData(this.currentPage, this.flush);
}

class ReaderChapterState {
  final Map<int, Chapter> chapterMap;

  ReaderChapterState(this.chapterMap);
}

class ReaderListData {
  final String mangaId;
  final int totalPageCount;
  final List<Chapter> chapterList;
  final Map<int, Chapter> chapterMap;
  final List<ReaderPageData> pageList;
  final List<ReaderDoublePageData> doublePageList;

  ReaderListData(
    this.mangaId,
    this.totalPageCount,
    this.chapterList,
    this.chapterMap,
    this.pageList,
    this.doublePageList,
  );

  int pageIndexToIndex(int chapterIndex, int pageIndex) {
    int index = pageList.indexWhere((element) =>
        element.chapterIndex == chapterIndex && element.pageIndex == pageIndex);
    return index;
  }

  int doublePageIndexToIndex(int chapterIndex, int pageIndex) {
    int index = doublePageList.indexWhere((element) {
      bool m1 = element.first.chapterIndex == chapterIndex &&
          element.first.pageIndex == pageIndex;
      bool m2 = element.second?.chapterIndex == chapterIndex &&
          element.second?.pageIndex == pageIndex;
      return m1 || m2;
    });
    return index;
  }

  int doublePageListIndexToPageListIndex(int doubleIndex) {
    var count = 0;
    for (int i = 0; i < doublePageList.length && i <= doubleIndex; i++) {
      if (doublePageList[i].second != null) {
        count += 2;
      } else {
        count += 1;
      }
    }
    return count - 1;
  }

  int pageListIndexToDoublePageListIndex(int index) {
    var count = 0;
    for (int i = 0; i < doublePageList.length; i++) {
      if (doublePageList[i].second != null) {
        count += 2;
      } else {
        count += 1;
      }
      if (count - 1 >= index) {
        return i;
      }
    }
    return 0;
  }
}

@riverpod
class ReaderChapterStateWithMangeId extends _$ReaderChapterStateWithMangeId {
  @override
  ReaderChapterState build({required String mangaId}) {
    log("[Reader2] ReaderListState chapterState build with $mangaId");
    return ReaderChapterState({});
  }

  void upsertChapter(Chapter chapter, [bool reset = false]) {
    log("[Reader2] ReaderListState upsertChapter ${chapter.name} reset:$reset");

    final chapterMap = state.chapterMap;
    if (reset) {
      chapterMap.clear();
    }
    chapterMap[chapter.index!] = chapter;

    state = ReaderChapterState(chapterMap);
  }
}

@riverpod
class ReaderSinglePageSetWithMangeId extends _$ReaderSinglePageSetWithMangeId
    with StateProviderMixin<Set<String>> {
  @override
  Set<String> build({required String mangaId}) {
    return {};
  }
}

@riverpod
class ReaderListStateWithMangeId extends _$ReaderListStateWithMangeId {
  @override
  ReaderListData build({required String mangaId}) {
    log("[Reader2] ReaderListState build with $mangaId");
    final chapterState =
        ref.watch(readerChapterStateWithMangeIdProvider(mangaId: mangaId));
    final singlePageSet =
        ref.watch(readerSinglePageSetWithMangeIdProvider(mangaId: mangaId));
    final skipFirstPage = ref
        .watch(readerPageLayoutSkipFirstWithMangaIdProvider(mangaId: mangaId));
    log("[Reader2] skipFirstPage:$skipFirstPage, singlePageSet:$singlePageSet");
    return buildListData(mangaId, chapterState, singlePageSet, skipFirstPage);
  }

  ReaderListData buildListData(
    String mangaId,
    ReaderChapterState chapterState,
    Set<String> singlePageSet,
    bool? skipFirstPage,
  ) {
    final chapterMap = chapterState.chapterMap;

    final chapterList = chapterMap.values.toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));

    var totalPageCount = 0;
    final List<ReaderPageData> pageList = [];
    for (final chapter in chapterList) {
      final currPageCount = chapter.pageCount ?? 0;
      totalPageCount += currPageCount;
      for (int i = 0; i < currPageCount; i++) {
        pageList.add(ReaderPageData(
          chapter.index!,
          i,
          chapter.pageData?[i],
          chapter.id,
        ));
      }
    }

    final List<ReaderDoublePageData> doublePageList = [];
    for (final chapter in chapterList) {
      final currPageCount = chapter.pageCount ?? 0;
      for (int i = 0; i < currPageCount; i++) {
        final first = ReaderPageData(
          chapter.index!,
          i,
          chapter.pageData?[i],
          chapter.id,
        );
        final second = i + 1 < currPageCount
            ? ReaderPageData(
                chapter.index!,
                i + 1,
                chapter.pageData?[i + 1],
                chapter.id,
              )
            : null;
        if (i == 0 && skipFirstPage == true) {
          doublePageList.add(ReaderDoublePageData(first, null, true));
        }
        else if (singlePageSet.contains("${chapter.index}#$i")) {
          doublePageList.add(ReaderDoublePageData(first, null, true));
        }
        else if (second != null &&
            singlePageSet.contains("${chapter.index}#${i + 1}")) {
          doublePageList.add(ReaderDoublePageData(first, null, false));
        }
        else {
          doublePageList.add(ReaderDoublePageData(first, second, false));
          i++;
        }
      }
    }

    return ReaderListData(
      mangaId,
      totalPageCount,
      chapterList,
      chapterMap,
      pageList,
      doublePageList,
    );
  }
}
