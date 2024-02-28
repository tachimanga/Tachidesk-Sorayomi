// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/locale_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';

part 'update_controller.g.dart';

@riverpod
class CategoryIdsToUpdatePref extends _$CategoryIdsToUpdatePref
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
        ref,
        key: DBKeys.categoryIdsToUpdate.name,
        initial: DBKeys.categoryIdsToUpdate.initial,
      );
}

@riverpod
class AlwaysAskCategoryToUpdatePref extends _$AlwaysAskCategoryToUpdatePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.alwaysAskCategoryToUpdate.name,
    initial: DBKeys.alwaysAskCategoryToUpdate.initial,
  );
}
