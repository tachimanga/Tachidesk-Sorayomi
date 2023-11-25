// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/server_image.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../../../domain/downloads_queue/downloads_queue_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';
import '../controller/ad_controller.dart';
import '../controller/reader_controller.dart';
import '../controller/reader_controller_v2.dart';

class ChapterLoadingWidget extends HookConsumerWidget {
  const ChapterLoadingWidget({
    super.key,
    required this.mangaId,
    required this.lastChapterIndex,
    required this.scrollDirection,
    required this.singlePageMode,
  });

  final String mangaId;
  final String lastChapterIndex;
  final Axis scrollDirection;
  final bool singlePageMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
    final prevNextChapterProvider = useMemoized(
        () => getPreviousAndNextChaptersProvider(
              mangaId: mangaId,
              chapterIndex: lastChapterIndex,
            ),
        []);
    final prevNextChapterPair = ref.watch(prevNextChapterProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final bannerAd = singlePageMode
        ? AsyncData(BannerAdData())
        : ref.watch(bannerAdWithKeyProvider(
            width: screenWidth,
            key: "$mangaId#$lastChapterIndex",
          ));

    if (prevNextChapterPair?.first == null) {
      if (singlePageMode) {
        return Center(
          child: Text(context.l10n!.noNextChapter),
        );
      }
      // return const SizedBox.shrink();
      return adWidget(bannerAd);
    }

    final nextChapterBasic = prevNextChapterPair!.first!;
    final chapterProviderWithIndex = useMemoized(
        () => chapterWithIdProvider(
            mangaId: mangaId, chapterIndex: "${nextChapterBasic.index}"),
        []);
    final nextChapter = ref.watch(chapterProviderWithIndex);

    useEffect(() {
      //print("[AD_V2]ChapterLoadingWidget create $mangaId $lastChapterIndex");
      ref.read(chapterProviderWithIndex.notifier).keepAlive();
      return;
    }, []);

    return nextChapter.showUiWhenData(
      context,
      // (data) => const SizedBox.shrink(), // const Text("load succ"),
      (data) => adWidget(bannerAd),
      refresh: () => ref.refresh(chapterProviderWithIndex),
      wrapper: (child) => Padding(
        padding: EdgeInsets.only(bottom: max(0, windowPadding.bottom - 14)),
        child: SizedBox(
          height: scrollDirection == Axis.vertical ? context.width : null,
          width: scrollDirection == Axis.horizontal ? context.width : null,
          child: child,
        ),
      ),
    );
  }

  Widget adWidget(AsyncValue<BannerAdData?> bannerAd) {
    return bannerAd.when(
      data: (data) {
        if (data?.loaded == true) {
          return BannerAdWidget(
            ad: data!.bannerAd!,
            scrollDirection: scrollDirection,
          );
        }
        return const SizedBox.shrink();
      },
      error: (err, stack) => const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
    );
  }
}

final Set<BannerAd> _mountedAds = <BannerAd>{};

class BannerAdWidget extends HookConsumerWidget {
  const BannerAdWidget({
    super.key,
    required this.ad,
    required this.scrollDirection,
  });

  final BannerAd ad;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
    final mounted = useMemoized(() => _mountedAds.contains(ad));
    // if (kDebugMode) {
    //   debugPrint("[AD_V2] ad mounted:$mounted");
    // }
    useEffect(() {
      // if (kDebugMode) {
      //   debugPrint("[AD_V2] ad mount");
      // }
      _mountedAds.add(ad);
      return () {
        // if (kDebugMode) {
        //   debugPrint("[AD_V2] ad un mount");
        // }
        _mountedAds.remove(ad);
      };
    }, []);

    if (mounted) {
      //return const Text("ad already mount");
      return const SizedBox.shrink();
    }
    return Padding(
      padding: scrollDirection == Axis.vertical
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: windowPadding.top, bottom: windowPadding.bottom),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
