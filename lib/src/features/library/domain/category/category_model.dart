// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../constants/enum.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

@freezed
class Category with _$Category {
  factory Category({
    int? id,
    String? name,
    int? order,
    @JsonKey(name: "default") bool? defaultCategory,
    CategoryMeta? meta,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}

@freezed
class CategoryMeta with _$CategoryMeta {
  factory CategoryMeta({
    @JsonKey(name: "flutter_sort") MangaSort? sort,
    @JsonKey(
      name: "flutter_sortDirection",
      fromJson: CategoryMeta.fromJsonToBool,
    )
    bool? sortDirection,
  }) = _CategoryMeta;

  static bool? fromJsonToBool(dynamic val) => val != null && val is String
      ? val == "true"
      : null;

  factory CategoryMeta.fromJson(Map<String, dynamic> json) =>
      _$CategoryMetaFromJson(json);
}

enum CategoryMetaKeys {
  sort("flutter_sort"),
  sortDirection("flutter_sortDirection"),
  ;

  const CategoryMetaKeys(this.key);
  final String key;
}
