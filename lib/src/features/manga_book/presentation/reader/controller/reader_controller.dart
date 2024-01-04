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
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import 'reader_controller_v2.dart';

part 'reader_controller.g.dart';

List<KeepAliveLink> chapterAliveLinkList = [];

@riverpod
class ChapterWithId extends _$ChapterWithId {
  @override
  Future<Chapter?> build({
    required String mangaId,
    required String chapterIndex,
  }) async {
    log('[Reader2] ChapterWithId. $mangaId#$chapterIndex create');
    ref.onDispose(() => log('[Reader2] ChapterWithId. $mangaId#$chapterIndex dispose'));
    final result = await ref.watch(mangaBookRepositoryProvider).getChapter(
          mangaId: mangaId,
          chapterIndex: chapterIndex,
        );
    updateReaderListState(result);
    return result;
  }

  Future<void> toggleBookmarked() async {
    final chapter = state.valueOrNull;
    if (chapter != null) {
      final update = chapter.copyWith(
          bookmarked: chapter.bookmarked != null ? !chapter.bookmarked! : null);
      state = AsyncValue.data(update);
      updateReaderListState(update);
    }
  }
  Future<void> loadChapter({
    required String mangaId,
    required String chapterIndex,
    required bool nextPage,
  }) async {
    log('[Reader2] loadChapter nextPage:$nextPage');
    final token = CancelToken();
    ref.onDispose(token.cancel);
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
            () => ref.watch(mangaBookRepositoryProvider).getChapter(
          mangaId: mangaId,
          chapterIndex: chapterIndex,
        ));

    updateReaderListState(result.valueOrNull, nextPage);
    state = result;
  }

  void updateReaderListState(Chapter? chapter, [bool reset=false]) {
    if (ref.read(useReader2Provider) != true) {
      return;
    }
    if (chapter != null) {
      final listProvider = readerListStateWithMangeIdProvider(mangaId: mangaId);
      ref.read(listProvider.notifier).upsertChapter(chapter, reset);
    }
  }

  void keepAlive() {
    final link = ref.keepAlive();
    chapterAliveLinkList.add(link);

    if (chapterAliveLinkList.length > 1) {
      //log('[AD_V2] close link.');
      final e = chapterAliveLinkList.removeAt(0);
      e.close();
    }
  }
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
  var hasShowRate = userDefaults.getString("mc.app.hasShowRate");
  final purchaseGate = ref.watch(purchaseGateProvider);
  var completer = Completer<MyBannerAd>();
  var empty = MyBannerAd();
  empty.loaded = false;

  if (adUnitId == null || adUnitId.isEmpty) {
    log('adUnitId is empty. $adUnitId ');
    completer.complete(empty);
    return completer.future;
  }

  if (purchaseGate == true) {
    log('premium not show ad');
    completer.complete(empty);
    return completer.future;
  }

  var magic = ref.watch(getMagicProvider);
  final magicPipe = ref.watch(getMagicPipeProvider);

  if (!magic.b0) {
    if (hasShowRate == null || hasShowRate.isEmpty) {
      log('wait rate $hasShowRate');
      magicPipe.invokeMethod("LogEvent", "LOAD_AD_WAIT");
      completer.complete(empty);
      return completer.future;
    }
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
