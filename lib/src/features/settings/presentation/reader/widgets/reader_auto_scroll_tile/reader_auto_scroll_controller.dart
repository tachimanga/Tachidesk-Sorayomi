// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../../../widgets/radio_list_popup.dart';

part 'reader_auto_scroll_controller.g.dart';

@riverpod
class AutoScrollIntervalPref extends _$AutoScrollIntervalPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.autoScrollInterval.initial,
        key: DBKeys.autoScrollInterval.name,
      );
}

@riverpod
class AutoSmoothScrollIntervalPref extends _$AutoSmoothScrollIntervalPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.autoSmoothScrollInterval.initial,
        key: DBKeys.autoSmoothScrollInterval.name,
      );
}

@riverpod
class LongPressScrollPref extends _$LongPressScrollPref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.longPressScroll.name,
        initial: DBKeys.longPressScroll.initial,
      );
}

@riverpod
class AutoScrolling extends _$AutoScrolling with StateProviderMixin<bool> {
  @override
  bool build() => false;
}

int autoScrollTransform(int input) {
  if (input.abs() < 4800) {
    return input;
  }
  // 5~10 to 5~30
  final x = 0.1 * pow(input / 1000, 2.477);
  return (x * 1000).toInt();
}
