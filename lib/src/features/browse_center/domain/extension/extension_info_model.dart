// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/freezed_converters/language_json_converter.dart';
import '../language/language_model.dart';
import '../source/source_model.dart';
import 'extension_model.dart';
import 'extension_tag.dart';

part 'extension_info_model.freezed.dart';
part 'extension_info_model.g.dart';

@freezed
class ExtensionInfo with _$ExtensionInfo {
  factory ExtensionInfo({
    Extension? extension,
    List<Source>? sources,
    String? changelogUrl,
    String? readmeUrl,
  }) = _ExtensionInfo;

  factory ExtensionInfo.fromJson(Map<String, dynamic> json) =>
      _$ExtensionInfoFromJson(json);
}
