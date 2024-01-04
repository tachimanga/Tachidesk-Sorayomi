// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart' as logger;
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/common_error_widget.dart';
import '../../../settings/presentation/appearance/controller/theme_controller.dart';
import '../../../settings/presentation/reader/widgets/reader_mode_tile/reader_mode_tile.dart';
import '../../../settings/presentation/reader/widgets/swipe_right_back_tile/swipe_right_back_tile.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter_patch/chapter_put_model.dart';
import '../manga_details/controller/manga_details_controller.dart';
import 'controller/reader_controller.dart';
import 'controller/reader_controller_v2.dart';
import 'widgets/reader_mode/continuous_reader_mode_v2.dart';
import 'widgets/reader_mode/single_page_reader_mode_v2.dart';

class ReaderScreen2 extends HookConsumerWidget {
  const ReaderScreen2({
    super.key,
    required this.mangaId,
    required this.initChapterIndex,
  });
  final String mangaId;
  final String initChapterIndex;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeData = ref.watch(themeSchemeColorProvider);
    final initChapterIndexState = useState(initChapterIndex);

    final readerListProvider = useMemoized(
        () => readerListStateWithMangeIdProvider(mangaId: mangaId), []);
    final readerListData = ref.watch(readerListProvider);

    final mangaProvider =
        useMemoized(() => mangaWithIdProvider(mangaId: mangaId), []);
    final chapterProviderWithIndex = useMemoized(
        () =>
            chapterWithIdProvider(mangaId: mangaId, chapterIndex: initChapterIndex),
        []);

    final manga = ref.watch(mangaProvider);
    final chapter = ref.watch(chapterProviderWithIndex);
    final defaultReaderMode = ref.watch(readerModeKeyProvider);
    //logger.log("[Reader2] ReaderScreen2.chapter ${chapter.valueOrNull?.name}, index:${chapter.valueOrNull?.index}");

    final debounce = useRef<Timer?>(null);
    final onPageChanged2 = useCallback<AsyncValueSetter<ReaderPageData>>(
      (ReaderPageData currentPage) async {
        final currChapter = readerListData.chapterList.firstWhereOrNull(
            (element) => element.index == currentPage.chapterIndex);
        logger.log("[Reader2] onPageChanged currChapter:${currChapter?.name}, "
            "currentPage:${currentPage.pageIndex}");
        if (currChapter == null) {
          //logger.log("[Reader2] currChapter is null");
          return;
        }

        if (currChapter.read == true ||
            currentPage.pageIndex <=
                currChapter.lastPageRead.ifNullOrNegative(0)) {
          //logger.log("[Reader2] no need update");
          return;
        }

        updateLastRead() async {
          final isReadingCompeted = currChapter.read == true ||
              currentPage.pageIndex + 1 >=
                  currChapter.pageCount.ifNullOrNegative(0);
          // logger.log("[Reader2] updateLastRead "
          //     "isRead:$isReadingCompeted index:${currentPage.pageIndex}");
          await AsyncValue.guard(
            () => ref.read(mangaBookRepositoryProvider).putChapter(
                  mangaId: mangaId,
                  chapterIndex: "${currentPage.chapterIndex}",
                  patch: ChapterPut(
                    lastPageRead: isReadingCompeted ? 0 : currentPage.pageIndex,
                    read: isReadingCompeted,
                  ),
                ),
          );
        }

        final finalDebounce = debounce.value;
        if ((finalDebounce?.isActive).ifNull()) {
          finalDebounce?.cancel();
        }
        if (currentPage.pageIndex + 1 >=
            currChapter.pageCount.ifNullOrNegative(0)) {
          updateLastRead();
        } else {
          debounce.value = Timer(const Duration(seconds: 2), updateLastRead);
        }
        return;
      },
      [readerListData],
    );

    useRouteObserver(routeObserver, didPop: () {
      logger.log("ReaderScreen did pop");
      ref.invalidate(mangaChapterListProvider(mangaId: mangaId));
    });

    final swipeRightMode =
        ref.watch(swipeRightBackPrefProvider) ?? SwipeRightToGoBackMode.always;
    final readerMode = manga.valueOrNull?.meta?.readerMode ?? defaultReaderMode;
    final disableSwipeRight =
        swipeRightMode == SwipeRightToGoBackMode.disable ||
            (swipeRightMode == SwipeRightToGoBackMode.disableWhenHorizontal &&
                (readerMode == ReaderMode.singleHorizontalLTR ||
                    readerMode == ReaderMode.singleHorizontalRTL ||
                    readerMode == ReaderMode.continuousHorizontalLTR ||
                    readerMode == ReaderMode.continuousHorizontalRTL));

    return WillPopScope(
        onWillPop: disableSwipeRight ? () async {
          return true;
        } : null,
        child: Theme(
              data: appThemeData.dark.copyWith(scaffoldBackgroundColor:
                Colors.black,
                appBarTheme: const AppBarTheme(
                  systemOverlayStyle: SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
                )
              ),
              child: manga.showUiWhenData(
                    context,
                        (data) {
                      if (data == null) return const SizedBox.shrink();
                      return chapter.showUiWhenData(
                        context,
                            (chapterData) {
                          if (chapterData == null
                              || chapterData.pageCount == null
                              || chapterData.pageCount! <= 0) {
                            return Scaffold(
                                appBar: AppBar(backgroundColor: Colors.black.withOpacity(.7)),
                                body: CommonErrorWidget(
                                    refresh: () => ref.refresh(chapterProviderWithIndex),
                                    error: "No Pages found"));
                          }
                          switch (data.meta?.readerMode ?? defaultReaderMode) {
                            case ReaderMode.singleVertical:
                              return SinglePageReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                scrollDirection: Axis.vertical,
                              );
                            case ReaderMode.singleHorizontalRTL:
                              return SinglePageReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                reverse: true,
                              );
                            case ReaderMode.continuousHorizontalLTR:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                scrollDirection: Axis.horizontal,
                              );
                            case ReaderMode.continuousHorizontalRTL:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                              );
                            case ReaderMode.singleHorizontalLTR:
                              return SinglePageReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                              );
                            case ReaderMode.continuousVertical:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                showSeparator: true,
                              );
                            case ReaderMode.webtoon:
                            default:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
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

          )
    );
  }
}
