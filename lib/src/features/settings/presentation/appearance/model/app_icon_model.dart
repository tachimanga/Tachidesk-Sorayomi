// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_icon_model.freezed.dart';
part 'app_icon_model.g.dart';

@freezed
class AppIconConfig with _$AppIconConfig {
  factory AppIconConfig({
    required List<AppIconItem> list,
  }) = _AppIconConfig;

  factory AppIconConfig.fromJson(Map<String, dynamic> json) =>
      _$AppIconConfigFromJson(json);
}

@freezed
class AppIconItem with _$AppIconItem {
  factory AppIconItem({
    required String key,
    String? name,
    String? author,
    String? link,
  }) = _AppIconItem;

  factory AppIconItem.fromJson(Map<String, dynamic> json) =>
      _$AppIconItemFromJson(json);
}
