// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../page_builder.dart';

part 'page_model.freezed.dart';
part 'page_model.g.dart';

enum MdPageCode {
  getStarted,
  findRepo,
  unknown,
  ;

  static final _map = <String, MdPageCode>{
    for (MdPageCode page in MdPageCode.values) page.name: page
  };
  static MdPageCode fromCode(String code) => _map[code] ?? unknown;

  MdPage buildPage(BuildContext context) {
    switch (this) {
      case getStarted:
        return buildGetStartedPage(context);
      case findRepo:
        return buildFindRepoPage(context);
      case unknown:
        return buildUnknownPage(context);
    }
  }
}

@freezed
class MdPage with _$MdPage {
  factory MdPage({
    required String title,
    required String content,
  }) = _MdPage;

  factory MdPage.fromJson(Map<String, dynamic> json) =>
      _$MdPageFromJson(json);
}
