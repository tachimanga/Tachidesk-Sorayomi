import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'pip_controller.g.dart';

@riverpod
class PipBuildFlag extends _$PipBuildFlag {
  @override
  bool build() {
    final userDefaults = ref.watch(sharedPreferencesProvider);
    return userDefaults.getString("config.pipBuild") == "1";
  }
}

@riverpod
class BgEnablePref extends _$BgEnablePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.bgEnable.name,
        initial: DBKeys.bgEnable.initial,
      );
}
