import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'category_settings_controller.g.dart';

@riverpod
class DefaultCategoryPref extends _$DefaultCategoryPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
    ref,
    initial: DBKeys.defaultCategory.initial,
    key: DBKeys.defaultCategory.name,
  );
}