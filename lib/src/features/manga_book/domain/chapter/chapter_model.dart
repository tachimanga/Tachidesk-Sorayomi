// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../img/image_model.dart';

part 'chapter_model.freezed.dart';
part 'chapter_model.g.dart';

@freezed
class Chapter with _$Chapter {
  factory Chapter({
    int? id,
    bool? bookmarked,
    double? chapterNumber,
    bool? downloaded,
    int? fetchedAt,
    // val index: Int, this chapter's index, starts with 1
    int? index,
    int? lastPageRead,
    int? lastReadAt,
    int? mangaId,
    String? name,
    int? pageCount,
    bool? read,
    String? realUrl,
    String? scanlator,
    int? uploadDate,
    String? url,
    Map<int, ImgData>? pageData,
    bool? resumeFlag,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
}

@freezed
class ScanlatorMeta with _$ScanlatorMeta {
  factory ScanlatorMeta({
    List<String>? list,
  }) = _ScanlatorMeta;

  factory ScanlatorMeta.fromJson(Map<String, dynamic> json) =>
      _$ScanlatorMetaFromJson(json);
}