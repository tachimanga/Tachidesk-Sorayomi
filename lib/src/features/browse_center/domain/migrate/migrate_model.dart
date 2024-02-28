// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../manga_book/domain/manga/manga_model.dart';
import '../source/source_model.dart';

part 'migrate_model.freezed.dart';
part 'migrate_model.g.dart';

@freezed
class MigrateInfo with _$MigrateInfo {
  factory MigrateInfo({
    bool? existInLibraryManga,
  }) = _MigrateInfo;

  factory MigrateInfo.fromJson(Map<String, dynamic> json) =>
      _$MigrateInfoFromJson(json);
}

@freezed
class MigrateSourceList with _$MigrateSourceList {
  factory MigrateSourceList({
    List<MigrateSource>? list,
  }) = _MigrateSourceList;

  factory MigrateSourceList.fromJson(Map<String, dynamic> json) =>
      _$MigrateSourceListFromJson(json);
}

@freezed
class MigrateSource with _$MigrateSource {
  factory MigrateSource({
    int? count,
    Source? source,
  }) = _MigrateSource;

  factory MigrateSource.fromJson(Map<String, dynamic> json) =>
      _$MigrateSourceFromJson(json);
}

@freezed
class MigrateMangaList with _$MigrateMangaList {
  factory MigrateMangaList({
    String? sourceId,
    List<Manga>? list,
  }) = _MigrateMangaList;

  factory MigrateMangaList.fromJson(Map<String, dynamic> json) =>
      _$MigrateMangaListFromJson(json);
}

@freezed
class MigrateRequest with _$MigrateRequest {
  factory MigrateRequest({
    int? srcMangaId,
    int? destMangaId,
    bool? migrateChapterFlag,
    bool? migrateCategoryFlag,
    bool? migrateTrackFlag,
    bool? replaceFlag,
  }) = _MigrateRequest;

  factory MigrateRequest.fromJson(Map<String, dynamic> json) =>
      _$MigrateRequestFromJson(json);
}

