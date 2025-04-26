// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_settings_model.freezed.dart';
part 'update_settings_model.g.dart';

@freezed
class UpdateRestrictions with _$UpdateRestrictions {
  factory UpdateRestrictions({
    bool? filteredByUpdateStrategy,
    bool? filteredByMangaStatus,
    bool? filteredByMangaUnread,
    bool? filteredByMangaNotStart,
  }) = _UpdateRestrictions;

  factory UpdateRestrictions.fromJson(Map<String, dynamic> json) =>
      _$UpdateRestrictionsFromJson(json);
}
