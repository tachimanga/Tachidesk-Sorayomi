// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../constants/enum.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../source/source_model.dart';

part 'browse_model.freezed.dart';
part 'browse_model.g.dart';

@freezed
class UrlFetchInput with _$UrlFetchInput {
  factory UrlFetchInput({
    required UrlFetchType type,
    int? sourceId,
    int? mangaId,
    int? chapterId,
    int? chapterIndex,
  }) = _UrlFetchInput;

  factory UrlFetchInput.fromJson(Map<String, dynamic> json) =>
      _$UrlFetchInputFromJson(json);

  factory UrlFetchInput.ofSource(int? sourceId) => UrlFetchInput(
        type: UrlFetchType.source,
        sourceId: sourceId,
      );
  factory UrlFetchInput.ofManga(int? mangaId) => UrlFetchInput(
        type: UrlFetchType.manga,
        mangaId: mangaId,
      );
  factory UrlFetchInput.ofChapterId(int? chapterId) => UrlFetchInput(
        type: UrlFetchType.chapter,
        chapterId: chapterId,
      );
  factory UrlFetchInput.ofChapterIndex(int? mangaId, int? chapterIndex) =>
      UrlFetchInput(
        type: UrlFetchType.chapter,
        mangaId: mangaId,
        chapterIndex: chapterIndex,
      );
}

@freezed
class UrlFetchOutput with _$UrlFetchOutput {
  factory UrlFetchOutput({
    String? url,
    String? userAgent,
  }) = _UrlFetchOutput;

  factory UrlFetchOutput.fromJson(Map<String, dynamic> json) =>
      _$UrlFetchOutputFromJson(json);
}
