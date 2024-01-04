// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

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

part 'global_providers.g.dart';

@riverpod
DioClient dioClientKey(ref) => DioClient(
      dio: ref.watch(networkModuleProvider).provideDio(
            baseUrl: ref.watch(serverUrlProvider) ?? DBKeys.serverUrl.initial,
            authType: ref.watch(authTypeKeyProvider) ?? DBKeys.authType.initial,
            credentials: ref.watch(credentialsProvider),
          ),
      pipe: ref.watch(getMagicPipeProvider),
    );

@riverpod
class AuthTypeKey extends _$AuthTypeKey
    with SharedPreferenceEnumClientMixin<AuthType> {
  @override
  AuthType? build() => initialize(
        ref,
        initial: DBKeys.authType.initial,
        key: DBKeys.authType.name,
        enumList: AuthType.values,
      );
}

class Magic {
  bool a0 = true; // enable repo tag, show broken status
  bool a1 = false; // no use
  bool a2 = false; // no use
  bool a3 = false; // no use
  bool a4 = false; // no use
  bool a5 = false; // no use
  bool a6 = true; // enable install apk
  bool a7 = true; // enable nsfw
  bool a8 = true; // enable nsfw settings
  bool a9 = false; // enable custom repo url
  bool b0 = true; // enable ads
  bool b1 = false; // no use
  bool b2 = false; // no use
  bool b3 = false; // no use
  bool b4 = false; // no use
  bool b5 = false; // no use
  bool b6 = false; // no use
  bool b7 = false; // no use
  bool b8 = false; // no use
  bool b9 = false; // no use
}

@riverpod
Magic getMagic(GetMagicRef ref) {
  final magic = Magic();
  final userDefaults = ref.watch(sharedPreferencesProvider);
  magic.a0 = userDefaults.getBool("flutter.config.a0") ?? false;
  magic.a6 = userDefaults.getBool("flutter.config.a7") ?? false;
  magic.a7 = userDefaults.getBool("flutter.config.a7") ?? false;
  magic.a9 = userDefaults.getBool("flutter.config.a9") ?? false;
  magic.b1 = userDefaults.getBool("flutter.config.b1") ?? false;
  return magic;
}

@riverpod
MethodChannel getMagicPipe(GetMagicPipeRef ref) {
  var pipe = const MethodChannel('MAGIC_PIPE');
  return pipe;
}

@riverpod
MethodChannel notifyChannel(NotifyChannelRef ref) {
  final pipe = const MethodChannel('MC_NOTIFY');
  return pipe;
}

@riverpod
class InstallLocalCount extends _$InstallLocalCount
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
    ref,
    initial: DBKeys.installLocalCount.initial,
    key: DBKeys.installLocalCount.name,
  );
}


@riverpod
class L10n extends _$L10n with SharedPreferenceClientMixin<Locale> {
  Map<String, String> toJson(Locale locale) => {
        if (locale.countryCode.isNotBlank) "countryCode": locale.countryCode!,
        if (locale.languageCode.isNotBlank) "languageCode": locale.languageCode,
        if (locale.scriptCode.isNotBlank) "scriptCode": locale.scriptCode!,
      };
  Locale? fromJson(dynamic json) =>
      json is! Map<String, dynamic> || (json["languageCode"] == null)
          ? null
          : Locale.fromSubtags(
              languageCode: json["languageCode"]!.toString(),
              scriptCode: json["scriptCode"]?.toString(),
              countryCode: json["countryCode"]?.toString(),
            );
  @override
  Locale? build() => initialize(
        ref,
        key: DBKeys.l10n.name,
        initial: DBKeys.l10n.initial,
        fromJson: fromJson,
        toJson: toJson,
      );
}

@riverpod
SharedPreferences sharedPreferences(ref) => throw UnimplementedError();

@riverpod
Map<String, String>? systemProxy(ref) => throw UnimplementedError();