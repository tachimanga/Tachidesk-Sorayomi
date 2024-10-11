// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

const Duration kDuration = Duration(milliseconds: 500);
const Duration kInstantDuration = Duration(milliseconds: 1);
const Duration kLongDuration = Duration(seconds: 2);

const Curve kCurve = Curves.easeIn;
const Size kMagnifierSize = Size(77.37, 37.9);
const MagnifierDecoration kMagnifierDecoration = MagnifierDecoration(
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(40))),
  shadows: <BoxShadow>[
    BoxShadow(
        blurRadius: 1.5,
        offset: Offset(0, 2),
        spreadRadius: 0.75,
        color: Color.fromARGB(25, 0, 0, 0))
  ],
);

const kDebounceDuration = Duration(milliseconds: 500);
const kCategoryAlwaysAskValue = -1;

const kMangaCoverDecodeWidth = 240;

const kDefaultAppIconKey = "default";

const kSettingPadding = EdgeInsetsDirectional.only(start: 16.0, end: 10.0);
const kSettingTrailing = Icon(Icons.navigate_next, color: Color(0xFF616161));