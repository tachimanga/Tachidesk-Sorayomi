import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'security_controller.g.dart';

@riverpod
class LockTypePref extends _$LockTypePref
    with SharedPreferenceEnumClientMixin<LockTypeEnum> {
  @override
  LockTypeEnum? build() => initialize(
        ref,
        initial: DBKeys.lockType.initial,
        key: DBKeys.lockType.name,
        enumList: LockTypeEnum.values,
      );
}

@riverpod
class LockIntervalPref extends _$LockIntervalPref
    with SharedPreferenceEnumClientMixin<LockIntervalEnum> {
  @override
  LockIntervalEnum? build() => initialize(
        ref,
        initial: DBKeys.lockInterval.initial,
        key: DBKeys.lockInterval.name,
        enumList: LockIntervalEnum.values,
      );
}

@riverpod
class LockPasscodePref extends _$LockPasscodePref
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: DBKeys.lockPasscode.name,
        initial: DBKeys.lockPasscode.initial,
      );
}

@riverpod
class SecureScreenPref extends _$SecureScreenPref
    with SharedPreferenceEnumClientMixin<SecureScreenEnum> {
  @override
  SecureScreenEnum? build() => initialize(
        ref,
        initial: DBKeys.secureScreen.initial,
        key: DBKeys.secureScreen.name,
        enumList: SecureScreenEnum.values,
      );
}
