// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api3_model.freezed.dart';
part 'api3_model.g.dart';

@freezed
class InfoFetchResult with _$InfoFetchResult {
  const factory InfoFetchResult({
    String? code,
    String? message,
    InfoFetch? data,
  }) = _InfoFetchResult;

  factory InfoFetchResult.fromJson(Map<String, dynamic> json) =>
      _$InfoFetchResultFromJson(json);
}

@freezed
class InfoFetch with _$InfoFetch {
  const factory InfoFetch({
    SyncInfo? syncInfo,
  }) = _InfoFetch;

  factory InfoFetch.fromJson(Map<String, dynamic> json) =>
      _$InfoFetchFromJson(json);
}

@freezed
class SyncInfo with _$SyncInfo {
  const factory SyncInfo({
    String? notice,
    ButtonInfo? button,
  }) = _SyncInfo;

  factory SyncInfo.fromJson(Map<String, dynamic> json) =>
      _$SyncInfoFromJson(json);
}

@freezed
class ButtonInfo with _$ButtonInfo {
  const factory ButtonInfo({
    String? text,
    String? link,
  }) = _ButtonInfo;

  factory ButtonInfo.fromJson(Map<String, dynamic> json) =>
      _$ButtonInfoFromJson(json);
}

@freezed
class CallerInfo with _$CallerInfo {
  const factory CallerInfo({
    int? clientTimestamp,
    String? version,
    String? build,
    String? bundleId,
    String? deviceId,
    String? locale,
  }) = _CallerInfo;

  factory CallerInfo.fromJson(Map<String, dynamic> json) =>
      _$CallerInfoFromJson(json);
}
