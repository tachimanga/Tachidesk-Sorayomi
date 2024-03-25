// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/log.dart';

part 'ad_controller.g.dart';

List<KeepAliveLink> bannerAdAliveLinkList = [];

class BannerAdData {
  BannerAd? bannerAd;
  bool loaded = false;
}

@riverpod
Future<BannerAdData?> bannerAdWithKey(BannerAdWithKeyRef ref, {
  required String key,
  required double width,
}) async {
  final link = ref.keepAlive();
  bannerAdAliveLinkList.add(link);
  if (bannerAdAliveLinkList.length > 1) {
    final e = bannerAdAliveLinkList.removeAt(0);
    e.close();
  }

  final pipe = ref.watch(getMagicPipeProvider);

  final completer = Completer<BannerAdData>();
  final emptyAd = BannerAdData();
  emptyAd.loaded = false;

  final adParam = await pipe.invokeMethod("REQUEST_AD");
  log("[AD_V2] adParam:$adParam key:$key #width:$width");
  if (adParam == null || adParam is! Map || adParam["adId"] == null) {
    log("[AD_V2] adParam is null");
    completer.complete(emptyAd);
    return completer.future;
  }

  final adSize = adParam["bannerSize"];
  AdSize? size;
  if (adSize == "smart") {
    size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
    if (size == null) {
      log('[AD_V2]Unable to get height of anchored banner.');
      completer.complete(emptyAd);
      return completer.future;
    }
  } else if (adSize == "banner") {
    size = AdSize.banner;
  } else if (adSize == "largeBanner") {
    size = AdSize.largeBanner;
  } else if (adSize == "mediumRectangle") {
    size = AdSize.mediumRectangle;
  } else if (adSize == "fullBanner") {
    size = AdSize.fullBanner;
  } else if (adSize == "leaderboard") {
    size = AdSize.leaderboard;
  } else {
    size = AdSize.mediumRectangle;
  }

  log("[AD_V2]load ad");
  pipe.invokeMethod("LogEvent", "LOAD_AD_IN");
  final bannerAd = BannerAd(
    adUnitId: adParam["adId"],
    request: const AdRequest(),
    size: size,
    listener: BannerAdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (ad) {
        log('[AD_V2] onAdLoaded');
        pipe.invokeMethod("LogEvent", "LOAD_AD_SUCC");
        pipe.invokeMethod("MARK_AD_LOAD_SUCC");

        final value = BannerAdData();
        value.bannerAd = ad as BannerAd?;
        value.loaded = true;
        log('[AD_V2] onAdLoaded size w:${value.bannerAd?.size.width} '
            'h:${value.bannerAd?.size.height}');
        completer.complete(value);
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (ad, err) {
        log('[AD_V2] BannerAd failed to load: $err');
        logEvent2(pipe, "LOAD_AD_ERR", {
          "error": err.message,
        });
        ad.dispose();

        completer.complete(emptyAd);
      },
      onAdClicked: (Ad ad) {
        log('[AD_V2] onAdClicked');
        pipe.invokeMethod("MARK_AD_CLICK");
      },
    ),
  )..load();
  return completer.future;
}
