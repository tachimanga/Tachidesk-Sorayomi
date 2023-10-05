import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/db_keys.dart';
import '../constants/enum.dart';
import '../features/settings/presentation/server/widget/credential_popup/credentials_popup.dart';
import '../features/settings/widgets/server_url_tile/server_url_tile.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/mixin/shared_preferences_client_mixin.dart';
import '../utils/storage/dio/dio_client.dart';
import '../utils/storage/dio/network_module.dart';

part 'preference_providers.g.dart';

@riverpod
class UseSystemProxy extends _$UseSystemProxy with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.useSystemProxy.name,
    initial: DBKeys.useSystemProxy.initial,
  );
}

@riverpod
class UseNativeNet extends _$UseNativeNet with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: "config.flutterNativeNet",
    initial: true,
  );
}

@riverpod
class MaxConnPerHost extends _$MaxConnPerHost with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
    ref,
    key: "config.maxConnPerHost",
    initial: "3",
}

@riverpod
class JavaUseNativeNet extends _$JavaUseNativeNet with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: "config.javaNativeNet",
    initial: false,
  );
}