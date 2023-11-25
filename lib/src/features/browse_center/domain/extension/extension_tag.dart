// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/freezed_converters/language_json_converter.dart';
import '../language/language_model.dart';

part 'extension_tag.freezed.dart';
part 'extension_tag.g.dart';


@freezed
class ExtensionTagData with _$ExtensionTagData {
  factory ExtensionTagData({
    List<ExtensionTag>? list,
  }) = _ExtensionTagData;

  factory ExtensionTagData.fromJson(Map<String, dynamic> json) =>
      _$ExtensionTagDataFromJson(json);
}

@freezed
class ExtensionTag with _$ExtensionTag {
  factory ExtensionTag({
    String? pkg,
    bool? down,
    List<Tag>? tagList,
    String? suffix,
    bool? direct,
    bool? top,
  }) = _ExtensionTag;

  factory ExtensionTag.fromJson(Map<String, dynamic> json) =>
      _$ExtensionTagFromJson(json);
}

@freezed
class Tag with _$Tag {
  factory Tag({
    String? text,
    String? color,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) =>
      _$TagFromJson(json);
}

