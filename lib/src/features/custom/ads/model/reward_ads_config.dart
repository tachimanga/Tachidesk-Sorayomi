// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward_ads_config.freezed.dart';
part 'reward_ads_config.g.dart';

@freezed
class RewardAdsConfig with _$RewardAdsConfig {
  factory RewardAdsConfig({
    bool? enable,
    int? minDays,
    int? freeTicket,
    int? ticketPerAd,
    int? maxAds,
    String? adId,
    bool? skipWhenError,
  }) = _RewardAdsConfig;

  factory RewardAdsConfig.fromJson(Map<String, dynamic> json) => _$RewardAdsConfigFromJson(json);
}