// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'source_pref_model.freezed.dart';
part 'source_pref_model.g.dart';

@freezed
class SourcePref with _$SourcePref {
  factory SourcePref({
    String? type, //EditTextPreference
    SourcePrefProps? props,
  }) = _SourcePref;

  factory SourcePref.fromJson(Map<String, dynamic> json) => _$SourcePrefFromJson(json);
}

@freezed
class SourcePrefProps with _$SourcePrefProps {
  factory SourcePrefProps({
    String? key, //"Source display name"
    String? title, //"Source display name"
    String? summary, //"Here you can change the source displayed suffix",
    String? defaultValue, //""
    String? dialogTitle, //"Source display name"
    String? dialogMessage, //null
    String? text, //null
    String? defaultValueType, //"String"
    String? currentValue, //"
  }) = _SourcePrefProps;

  factory SourcePrefProps.fromJson(Map<String, dynamic> json) => _$SourcePrefPropsFromJson(json);
}
