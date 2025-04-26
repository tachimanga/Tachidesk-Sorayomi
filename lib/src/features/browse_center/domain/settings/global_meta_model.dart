// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../constants/enum.dart';
import '../../../browse_center/domain/source/source_model.dart';
import '../../../settings/domain/tracking/tracking_model.dart';
import '../../../settings/domain/update/update_settings_model.dart';

part 'global_meta_model.freezed.dart';
part 'global_meta_model.g.dart';

@freezed
class GlobalMeta with _$GlobalMeta {
  factory GlobalMeta({
    @JsonKey(
      name: "UpdateRestrictions",
      fromJson: GlobalMeta.fromJsonToUpdateRestrictions,
    )
    UpdateRestrictions? updateRestrictions,
  }) = _GlobalMeta;

  static UpdateRestrictions? fromJsonToUpdateRestrictions(String? value) {
    if (value == null) {
      return null;
    }
    final e = jsonDecode(value);
    return e is Map<String, dynamic> ? UpdateRestrictions.fromJson(e) : null;
  }

  factory GlobalMeta.fromJson(Map<String, dynamic> json) =>
      _$GlobalMetaFromJson(json);
}

enum GlobalMetaKeys {
  updateRestrictions("UpdateRestrictions"),
  ;

  const GlobalMetaKeys(this.key);
  final String key;
}
