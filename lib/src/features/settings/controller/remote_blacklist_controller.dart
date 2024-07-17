// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/log.dart';
import '../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../data/config/remote_blacklist_config.dart';


part 'remote_blacklist_controller.g.dart';

@riverpod
class BlacklistConfigJson extends _$BlacklistConfigJson
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: "config.blacklistConfig",
        initial: "{}",
      );
}

@riverpod
BlacklistConfig blacklistConfig(BlacklistConfigRef ref) {
  final s = ref.watch(blacklistConfigJsonProvider) ?? "{}";
  ref.keepAlive();
  var c = BlacklistConfig();
  try {
    c = BlacklistConfig.fromJson(json.decode(s));
  } catch (e) {
    log("blacklistConfig parse error:$e");
  }
  log("blacklistConfig:$c, json:$s");
  return c;
}
