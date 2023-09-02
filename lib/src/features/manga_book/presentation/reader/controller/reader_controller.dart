// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/log.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';

part 'reader_controller.g.dart';

@riverpod
FutureOr<Chapter?> chapter(
  ChapterRef ref, {
  required String mangaId,
  required String chapterIndex,
}) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref.watch(mangaBookRepositoryProvider).getChapter(
        mangaId: mangaId,
        chapterIndex: chapterIndex,
      );
  ref.keepAlive();
  return result;
}

class MyBannerAd {
  BannerAd? bannerAd;
  bool loaded = false;
}

@riverpod
FutureOr<MyBannerAd?> bannerAdAdaptive(BannerAdAdaptiveRef ref, {
  required double width
}) async {
  var userDefaults = ref.watch(sharedPreferencesProvider);
  var adUnitId = userDefaults.getString("config.adUnitId2");

  var completer = Completer<MyBannerAd>();
  var empty = MyBannerAd();
  empty.loaded = false;

  if (adUnitId == null || adUnitId.isEmpty) {
    log('adUnitId is empty. $adUnitId ');
    completer.complete(empty);
  }

  var magic = ref.watch(getMagicProvider);
  final magicPipe = ref.watch(getMagicPipeProvider);

  if (!magic.b0) {
      magicPipe.invokeMethod("LogEvent", "LOAD_AD_WAIT");
      completer.complete(empty);
  }

  final AnchoredAdaptiveBannerAdSize? size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
  if (size == null) {
    log('Unable to get height of anchored banner.');
    return completer.future;
  }
  log("load ad");
  magicPipe.invokeMethod("LogEvent", "LOAD_AD_IN");
  final bannerAd = BannerAd(
    adUnitId: adUnitId!,
    request: const AdRequest(),
    size: size,
    listener: BannerAdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (ad) {
        log('$ad loaded.');
        magicPipe.invokeMethod("LogEvent", "LOAD_AD_SUCC");
        var value = MyBannerAd();
        value.bannerAd = ad as BannerAd?;
        value.loaded = true;
        completer.complete(value);
      },
      // Called when an ad request failed.
      onAdFailedToLoad: (ad, err) {
        log('BannerAd failed to load: $err');
        magicPipe.invokeMethod("LogEvent", "LOAD_AD_ERR_${err.message}");
        // Dispose the ad here to free resources.
        ad.dispose();

        var value = MyBannerAd();
        value.bannerAd = ad as BannerAd?;
        value.loaded = false;
        completer.complete(value);
      },
    ),
  )..load();
  return completer.future;
}
