// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_meta_model.freezed.dart';
part 'source_meta_model.g.dart';

@freezed
class SourceMeta with _$SourceMeta {
  factory SourceMeta({
    int? sourceId,
    String? key,
    String? value,
  }) = _SourceMeta;

  factory SourceMeta.fromJson(Map<String, dynamic> json) =>
      _$SourceMetaFromJson(json);
}

@freezed
class SourceCustomFilterConfig with _$SourceCustomFilterConfig {
  factory SourceCustomFilterConfig({
    List<SourceCustomFilter>? filters,
  }) = _SourceCustomFilterConfig;

  factory SourceCustomFilterConfig.fromJson(Map<String, dynamic> json) =>
      _$SourceCustomFilterConfigFromJson(json);
}

@freezed
class SourceCustomFilter with _$SourceCustomFilter {
  factory SourceCustomFilter({
    String? title,
    List<Map<String, dynamic>>? filters,
  }) = _SourceCustomFilter;

  factory SourceCustomFilter.fromJson(Map<String, dynamic> json) =>
      _$SourceCustomFilterFromJson(json);
}
