// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../browse_center/domain/source/source_model.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../domain/backup/backup_model.dart';

part 'storage_model.freezed.dart';
part 'storage_model.g.dart';

@freezed
class StorageRawInfo with _$StorageRawInfo {
  factory StorageRawInfo({
    int? size,
    String? name,
    Map<String, StorageRawInfo>? subDirs,
  }) = _StorageRawInfo;
  factory StorageRawInfo.fromJson(Map<String, dynamic> json) =>
      _$StorageRawInfoFromJson(json);
}

@freezed
class StorageInfo with _$StorageInfo {
  factory StorageInfo({
    StorageRawInfo? rawInfo,
    int? totalSize,
    int? cacheSize,
    int? imageCacheSize,
    int? coverCacheSize,
    int? otherCacheSize,
    int? localSourceSize,
    int? downloadsSize,
    int? downloadsV1Size,
    int? backupSize,
    int? otherSize,
  }) = _StorageInfo;
  factory StorageInfo.fromJson(Map<String, dynamic> json) =>
      _$StorageInfoFromJson(json);
}

@freezed
class StorageOverviewInfo with _$StorageOverviewInfo {
  factory StorageOverviewInfo({
    double? totalCapacity,
    double? availableCapacity,
  }) = _StorageOverviewInfo;
  factory StorageOverviewInfo.fromJson(Map<String, dynamic> json) =>
      _$StorageOverviewInfoFromJson(json);
}

@freezed
class DownloadMangaQueryOutput with _$DownloadMangaQueryOutput {
  factory DownloadMangaQueryOutput({
    List<DownloadMangaQueryItem>? list,
    List<Source>? sourceList,
  }) = _DownloadMangaQueryOutput;
  factory DownloadMangaQueryOutput.fromJson(Map<String, dynamic> json) =>
      _$DownloadMangaQueryOutputFromJson(json);
}

@freezed
class DownloadMangaQueryItem with _$DownloadMangaQueryItem {
  factory DownloadMangaQueryItem({
    int? sourceIdx,
    int? mangaId,
    bool? inLibrary,
    int? lastDownloadAt,
    String? title,
  }) = _DownloadMangaQueryItem;
  factory DownloadMangaQueryItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadMangaQueryItemFromJson(json);
}

@freezed
class StorageDownloadViewModel with _$StorageDownloadViewModel {
  factory StorageDownloadViewModel({
    StorageRawInfo? rawInfo,
    String? title,
    int? size,
    bool? legacyDownload,
    // v2
    int? mangaId,
    bool? inLibrary,
    int? lastDownloadAt,
    Source? source,
    // v1
    String? sourceName,
  }) = _StorageDownloadViewModel;
  factory StorageDownloadViewModel.fromJson(Map<String, dynamic> json) =>
      _$StorageDownloadViewModelFromJson(json);
}

@freezed
class LegacyDownloadsInfo with _$LegacyDownloadsInfo {
  factory LegacyDownloadsInfo({
    String? title,
    String? source,
  }) = _LegacyDownloadsInfo;
  factory LegacyDownloadsInfo.fromJson(Map<String, dynamic> json) =>
      _$LegacyDownloadsInfoFromJson(json);
}

@freezed
class StorageLocalMangaViewModel with _$StorageLocalMangaViewModel {
  factory StorageLocalMangaViewModel({
    StorageRawInfo? rawInfo,
    Manga? manga,
  }) = _StorageLocalMangaViewModel;
  factory StorageLocalMangaViewModel.fromJson(Map<String, dynamic> json) =>
      _$StorageLocalMangaViewModelFromJson(json);
}

@freezed
class StorageBackupViewModel with _$StorageBackupViewModel {
  factory StorageBackupViewModel({
    StorageRawInfo? rawInfo,
    BackupItem? backup,
  }) = _StorageBackupViewModel;
  factory StorageBackupViewModel.fromJson(Map<String, dynamic> json) =>
      _$StorageBackupViewModelFromJson(json);
}