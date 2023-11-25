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
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/img/image_model.dart';

part 'reader_controller_v2.g.dart';

@riverpod
class UseReader2 extends _$UseReader2 with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: "config.useReader2",
    initial: true,
  );
}

@riverpod
class DownscaleImage extends _$DownscaleImage with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: "config.downscaleImage",
    initial: false,
  );
}

class ReaderPageData {
  final int chapterIndex;
  final int pageIndex;
  final ImgData? imageData;

  ReaderPageData(this.chapterIndex, this.pageIndex, this.imageData);
}

class ReaderListData {
  final String mangaId;
  final int totalPageCount;
  final List<Chapter> chapterList;
  final Map<int, Chapter> chapterMap;
  final List<ReaderPageData> pageList;

  ReaderListData(this.mangaId, this.totalPageCount, this.chapterList,
      this.chapterMap, this.pageList);

  int pageIndexToIndex(int chapterIndex, int pageIndex) {
    int index = pageList.indexWhere((element) => element.chapterIndex == chapterIndex
        && element.pageIndex == pageIndex);
    return index;
  }
}

@riverpod
class ReaderListStateWithMangeId extends _$ReaderListStateWithMangeId {
  @override
  ReaderListData build({required String mangaId}) {
    log("[Reader2] ReaderListState build with $mangaId");
    return ReaderListData(mangaId, 0, [], {}, []);
  }

  void upsertChapter(Chapter chapter, [bool reset=false]) {
    log("[Reader2] ReaderListState upsertChapter ${chapter.name}");

    final chapterMap = state.chapterMap;
    if (reset) {
      chapterMap.clear();
    }
    chapterMap[chapter.index!] = chapter;

    final chapterList = chapterMap.values.toList()
      ..sort((a, b) => a.index!.compareTo(b.index!));

    var totalPageCount = 0;
    final List<ReaderPageData> pageList = [];
    for (chapter in chapterList) {
      final currPageCount = chapter.pageCount ?? 0;
      totalPageCount += currPageCount;
      for (int i = 0; i < currPageCount; i++) {
        pageList.add(ReaderPageData(chapter.index!, i, chapter.pageData?[i]));
      }
    }

    state = ReaderListData(state.mangaId, totalPageCount, chapterList, chapterMap, pageList);
  }
}

