// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/db_keys.dart';
import '../../../utils/log.dart';
import '../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../data/stats_repository.dart';
import '../domain/stats_model.dart';

part 'stats_controller.g.dart';

@riverpod
Future<ReadTimeStats?> readTimeStats(ReadTimeStatsRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(statsRepositoryProvider)
      .queryReadTimeStats(cancelToken: token);
  return result;
}

@riverpod
class ReadTimeConfigJson extends _$ReadTimeConfigJson
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: "config.readTimeConfig",
        initial: "{}",
      );
}

@riverpod
ReadTimeConfig readTimeConfig(ReadTimeConfigRef ref) {
  final s = ref.watch(readTimeConfigJsonProvider) ?? "{}";
  ref.keepAlive();
  var c = ReadTimeConfig();
  try {
    c = ReadTimeConfig.fromJson(json.decode(s));
  } catch (e) {
    log("ReadTimeConfig parse error:$e");
  }
  log("ReadTimeConfig:$c, json:$s");
  return c;
}

@riverpod
class RemoteShowLogo extends _$RemoteShowLogo
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: "config.readTimeShowLogo",
        initial: true,
      );
}

@riverpod
class LocalShowLogo extends _$LocalShowLogo
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.readTimeShowLogo.name,
        initial: DBKeys.readTimeShowLogo.initial,
      );
}
