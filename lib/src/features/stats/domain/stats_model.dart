// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../manga_book/domain/manga/manga_model.dart';

part 'stats_model.freezed.dart';
part 'stats_model.g.dart';

@freezed
class ReadTimeStats with _$ReadTimeStats {
  factory ReadTimeStats({
    int? totalSeconds,
    List<Manga>? mangaList,
  }) = _ReadTimeStats;

  factory ReadTimeStats.fromJson(Map<String, dynamic> json) =>
      _$ReadTimeStatsFromJson(json);
}

@freezed
class ReadTimeConfig with _$ReadTimeConfig {
  factory ReadTimeConfig({
    double? threshold,
    List<String>? quoteList,
  }) = _ReadTimeConfig;

  factory ReadTimeConfig.fromJson(Map<String, dynamic> json) =>
      _$ReadTimeConfigFromJson(json);
}
