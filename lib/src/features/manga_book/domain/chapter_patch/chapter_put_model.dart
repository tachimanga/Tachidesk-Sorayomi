// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter_put_model.freezed.dart';
part 'chapter_put_model.g.dart';

@freezed
class ChapterPut with _$ChapterPut {
  factory ChapterPut({
    bool? read,
    bool? bookmarked,
    bool? markPrevRead,
    int? lastPageRead,
  }) = _ChapterPut;

  factory ChapterPut.fromJson(Map<String, dynamic> json) =>
      _$ChapterPutFromJson(json);
}

@freezed
class ChapterModifyInput with _$ChapterModifyInput {
  factory ChapterModifyInput({
    int? mangaId,
    int? chapterId,
    bool? read,
    bool? bookmarked,
    bool? markPrevRead,
    int? lastPageRead,
    bool? incognito,
  }) = _ChapterModifyInput;

  factory ChapterModifyInput.fromJson(Map<String, dynamic> json) =>
      _$ChapterModifyInputFromJson(json);
}

