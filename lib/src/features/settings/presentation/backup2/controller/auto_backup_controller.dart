import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'auto_backup_controller.g.dart';

@riverpod
class AutoBackupFrequency extends _$AutoBackupFrequency
    with SharedPreferenceEnumClientMixin<FrequencyEnum> {
  @override
  FrequencyEnum? build() => initialize(
    ref,
    initial: DBKeys.autoBackupFrequency.initial,
    key: DBKeys.autoBackupFrequency.name,
    enumList: FrequencyEnum.values,
  );
}

@riverpod
class AutoBackupLimit extends _$AutoBackupLimit
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.autoBackupLimit.initial,
        key: DBKeys.autoBackupLimit.name,
      );
}