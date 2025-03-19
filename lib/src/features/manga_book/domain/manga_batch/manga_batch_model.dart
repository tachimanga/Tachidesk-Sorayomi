// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'manga_batch_model.freezed.dart';
part 'manga_batch_model.g.dart';

@freezed
class MangaBatchInput with _$MangaBatchInput {
  factory MangaBatchInput({
    List<MangaChange>? changes,
  }) = _ChapterBatch;

  factory MangaBatchInput.fromJson(Map<String, dynamic> json) =>
      _$MangaBatchInputFromJson(json);
}

@freezed
class MangaChange with _$MangaChange {
  factory MangaChange({
    int? mangaId,
    bool? removeFromLibrary,
    bool? removeDownloads,
    List<int>? categoryIds,
    bool? chapterRead,
  }) = _MangaChange;

  factory MangaChange.fromJson(Map<String, dynamic> json) =>
      _$MangaChangeFromJson(json);
}
