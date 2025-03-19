// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/radio_list_popup.dart';

part 'reader_apple_pencil_controller.g.dart';

@riverpod
class ApplePencilDoubleTabPref extends _$ApplePencilDoubleTabPref
    with SharedPreferenceEnumClientMixin<ApplePencilActon> {
  @override
  ApplePencilActon? build() => initialize(
        ref,
        initial: DBKeys.applePencilDoubleTapAction.initial,
        key: DBKeys.applePencilDoubleTapAction.name,
        enumList: ApplePencilActon.values,
      );
}

@riverpod
class ApplePencilSqueezePref extends _$ApplePencilSqueezePref
    with SharedPreferenceEnumClientMixin<ApplePencilActon> {
  @override
  ApplePencilActon? build() => initialize(
        ref,
        initial: DBKeys.applePencilSqueezeAction.initial,
        key: DBKeys.applePencilSqueezeAction.name,
        enumList: ApplePencilActon.values,
      );
}
