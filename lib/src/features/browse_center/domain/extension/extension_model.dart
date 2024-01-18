// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/freezed_converters/language_json_converter.dart';
import '../language/language_model.dart';
import 'extension_tag.dart';

part 'extension_model.freezed.dart';
part 'extension_model.g.dart';

@freezed
class Extension with _$Extension {
  factory Extension({
    String? apkName,
    bool? hasUpdate,
    bool? hasReadme,
    bool? hasChangelog,
    String? iconUrl,
    bool? installed,
    bool? isNsfw,
    @JsonKey(
      fromJson: LanguageJsonConverter.fromJson,
      toJson: LanguageJsonConverter.toJson,
    )
        Language? lang,
    String? name,
    bool? obsolete,
    String? pkgName,
    String? pkgFactory,
    int? versionCode,
    String? versionName,
    List<Tag>? tagList,

    int? extensionId,
    int? repoId,
    String? repoName,
  }) = _Extension;

  factory Extension.fromJson(Map<String, dynamic> json) =>
      _$ExtensionFromJson(json);
}
