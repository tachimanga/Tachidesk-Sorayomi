// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

part of '../custom_extensions.dart';

extension BoolExtensions on bool? {
  bool ifNull([bool? alternative]) => this ?? alternative ?? false;
  // const val STATE_IGNORE  = 0 <-> null
  // const val STATE_INCLUDE = 1 <-> true
  // const val STATE_EXCLUDE = 2 <-> false
  int? get toInt => this != null ? (this! ? 1 : 2) : 0;
}
