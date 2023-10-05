// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart' as logger;
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/common_error_widget.dart';
import '../../../settings/presentation/reader/widgets/reader_mode_tile/reader_mode_tile.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter_patch/chapter_put_model.dart';
import '../manga_details/controller/manga_details_controller.dart';
import 'controller/reader_controller.dart';
import 'widgets/reader_mode/continuous_reader_mode.dart';
import 'widgets/reader_mode/single_page_reader_mode.dart';

class ReaderScreen extends HookConsumerWidget {
  const ReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterIndex,
  });
  final String mangaId;
  final String chapterIndex;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final bannerAd = ref.watch(bannerAdProvider);
    var screenWidth = MediaQuery.of(context).size.width;
    final bannerAd = ref.watch(bannerAdAdaptiveProvider(width: screenWidth));

    final mangaProvider =
        useMemoized(() => mangaWithIdProvider(mangaId: mangaId), []);
    final chapterProviderWithIndex = useMemoized(
        () => chapterWithIdProvider(mangaId: mangaId, chapterIndex: chapterIndex),
        []);

    final manga = ref.watch(mangaProvider);
    final chapter = ref.watch(chapterProviderWithIndex);
    final defaultReaderMode = ref.watch(readerModeKeyProvider);

    final debounce = useRef<Timer?>(null);
    final onPageChanged = useCallback<AsyncValueSetter<int>>(
      (int currentPage) async {
        final chapterValue = chapter.valueOrNull;
        if ((chapterValue?.read).ifNull() ||
            (chapterValue?.lastPageRead).ifNullOrNegative() >= currentPage) {
          return;
        }

        updateLastRead() async {
          final chapterValue = chapter.valueOrNull;
          final isReadingCompeted = chapterValue != null &&
              ((chapterValue.read).ifNull() ||
                  (currentPage >=
                      ((chapterValue.pageCount).ifNullOrNegative() - 1)));
          await AsyncValue.guard(
            () => ref.read(mangaBookRepositoryProvider).putChapter(
                  mangaId: mangaId,
                  chapterIndex: chapterIndex,
                  patch: ChapterPut(
                    lastPageRead: isReadingCompeted ? 0 : currentPage,
                    read: isReadingCompeted,
                  ),
                ),
          );
        }

        final finalDebounce = debounce.value;
        if ((finalDebounce?.isActive).ifNull()) {
          finalDebounce?.cancel();
        }

        if ((currentPage >=
            ((chapter.valueOrNull?.pageCount).ifNullOrNegative() - 1))) {
          updateLastRead();
        } else {
          debounce.value = Timer(const Duration(seconds: 2), updateLastRead);
        }
        return;
      },
      [chapter],
    );

    useRouteObserver(routeObserver, didPop: () {
      logger.log("ReaderScreen did pop");
      //ref.invalidate(chapterProviderWithIndex);
      ref.invalidate(mangaChapterListProvider(mangaId: mangaId));
    });

    final safeAreaBottom = MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom;
    return WillPopScope(
      onWillPop: null,
      child: Theme(
              data: defaultTheme.dark.copyWith(scaffoldBackgroundColor:
                Colors.black,
                appBarTheme: const AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
                )
              ),
              child: Column(
              children: [
                Expanded(
              child: manga.showUiWhenData(
                    context,
                        (data) {
                      if (data == null) return const SizedBox.shrink();
                      return chapter.showUiWhenData(
                        context,
                            (chapterData) {
                          if (chapterData == null
                              || chapterData.pageCount == null
                              || chapterData.pageCount == 0) {
                            return Scaffold(
                                appBar: AppBar(backgroundColor: Colors.black.withOpacity(.7)),
                                body: CommonErrorWidget(
                                    refresh: () => ref.refresh(chapterProviderWithIndex),
                                    error: "No Pages found"));
                          }
                          switch (data.meta?.readerMode ?? defaultReaderMode) {
                            case ReaderMode.singleVertical:
                              return SinglePageReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                                scrollDirection: Axis.vertical,
                              );
                            case ReaderMode.singleHorizontalRTL:
                              return SinglePageReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                                reverse: true,
                              );
                            case ReaderMode.continuousHorizontalLTR:
                              return ContinuousReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                                scrollDirection: Axis.horizontal,
                              );
                            case ReaderMode.continuousHorizontalRTL:
                              return ContinuousReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                              );
                            case ReaderMode.singleHorizontalLTR:
                              return SinglePageReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                              );
                            case ReaderMode.continuousVertical:
                              return ContinuousReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                                showSeparator: true,
                              );
                            case ReaderMode.webtoon:
                            default:
                              return ContinuousReaderMode(
                                chapter: chapterData,
                                manga: data,
                                onPageChanged: onPageChanged,
                              );
                          }
                        },
                        refresh: () => ref.refresh(chapterProviderWithIndex),
                        addScaffoldWrapper: true,
                      );
                    },
                    addScaffoldWrapper: true,
                    refresh: () => ref.refresh(mangaProvider),
                  ),
                ),
                if (bannerAd.hasValue && bannerAd.value?.loaded == true) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: max(0, safeAreaBottom - 14)),
                    child: SizedBox(
                      width: bannerAd.value!.bannerAd!.size.width.toDouble(),
                      height: bannerAd.value!.bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: bannerAd.value!.bannerAd!),
                    )
                  )
                ],
              ],
            ),
          )
    );
  }
}
