// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../utils/log.dart';
import '../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../model/reward_ads_config.dart';

part 'reward_ads_controller.g.dart';

@riverpod
class RewardAdsConfigJson extends _$RewardAdsConfigJson
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: "config.rewardAdsConfig",
        initial: "{}",
      );
}

@riverpod
RewardAdsConfig rewardAdsConfig(RewardAdsConfigRef ref) {
  final s = ref.watch(rewardAdsConfigJsonProvider) ?? "{}";
  ref.keepAlive();
  var c = RewardAdsConfig();
  try {
    c = RewardAdsConfig.fromJson(json.decode(s));
  } catch (e) {
    log("rewardAdsConfig parse error:$e");
  }
  log("[AD]rewardAdsConfig:$c, json:$s");
  return c;
}