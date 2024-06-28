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

import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/auto_delete.dart';
import '../../../../utils/classes/trace/trace_ref.dart';
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
import 'widgets/reader_mode/page_reader_mode.dart';

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
    final magic = ref.watch(getMagicProvider);
    final pipe = ref.watch(getMagicPipeProvider);

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

    final mangaBookRepository = ref.read(mangaBookRepositoryProvider);

    final manga = ref.watch(mangaProvider);
    final chapter = ref.watch(chapterProviderWithIndex);
    //logger.log("[Reader2] ReaderScreen2.chapter ${chapter.valueOrNull?.name}, index:${chapter.valueOrNull?.index}");

    final globalReaderMode = ref.watch(readerModeKeyProvider) ?? ReaderMode.webtoon;
    final mangaReaderMode = manga.valueOrNull?.meta?.readerMode ?? ReaderMode.defaultReader;
    final readerMode = mangaReaderMode == ReaderMode.defaultReader
        ? globalReaderMode : mangaReaderMode;

    useEffect(() {
      TraceRef.put(manga.valueOrNull?.sourceId, mangaId);
      return;
    }, [manga]);

    final chapterList = ref.watch(mangaChapterListProvider(mangaId: mangaId));
    final chapterRealUrl = chapterList.valueOrNull
            ?.where((e) => "${e.index}" == initChapterIndexState.value)
            .firstOrNull
            ?.realUrl;

    final debounce = useRef<Timer?>(null);
    final onPageChanged2 = useCallback<AsyncValueSetter<PageChangedData>>(
      (PageChangedData pageChangedData) async {
        final currentPage = pageChangedData.currentPage;
        final flush = pageChangedData.flush;

        final currChapter = readerListData.chapterList.firstWhereOrNull(
            (element) => element.index == currentPage.chapterIndex);
        logger.log("[Reader2] onPageChanged currChapter:${currChapter?.name}, "
            "currentPage:${currentPage.pageIndex}, flush:$flush");
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
            () => mangaBookRepository.putChapter(
                  mangaId: mangaId,
                  chapterIndex: "${currentPage.chapterIndex}",
                  patch: ChapterPut(
                    lastPageRead: isReadingCompeted ? 0 : currentPage.pageIndex,
                    read: isReadingCompeted,
                  ),
                ),
          );

          if (isReadingCompeted && currChapter.downloaded == true) {
            AutoDelete.instance.addToDeleteList(ref, currChapter);
          }
        }

        final finalDebounce = debounce.value;
        if ((finalDebounce?.isActive).ifNull()) {
          finalDebounce?.cancel();
        }
        if (currentPage.pageIndex + 1 >=
            currChapter.pageCount.ifNullOrNegative(0) || flush) {
          updateLastRead();
        } else {
          debounce.value = Timer(const Duration(seconds: 2), updateLastRead);
        }
        return;
      },
      [readerListData],
    );

    final AsyncCallback? onNoNextChapter = magic.c3 ? () async {
      logger.log("[Reader2] no next chapter");
      pipe.invokeMethod("READER:NO_CHAPTER_AD");
    } : null;

    useRouteObserver(routeObserver, didPop: () {
      logger.log("ReaderScreen did pop");

      // trigger auto delete
      AutoDelete.instance.triggerDelete(ref);

      ref.invalidate(mangaChapterListProvider(mangaId: mangaId));
    });

    final swipeRightMode =
        ref.watch(swipeRightBackPrefProvider) ?? SwipeRightToGoBackMode.always;
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
                          switch (readerMode) {
                            case ReaderMode.singleVertical:
                              return PageReaderMode(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                                scrollDirection: Axis.vertical,
                              );
                            case ReaderMode.singleHorizontalRTL:
                              return PageReaderMode(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                                reverse: true,
                              );
                            case ReaderMode.continuousHorizontalLTR:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                                scrollDirection: Axis.horizontal,
                              );
                            case ReaderMode.continuousHorizontalRTL:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                              );
                            case ReaderMode.singleHorizontalLTR:
                              return PageReaderMode(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                              );
                            case ReaderMode.continuousVertical:
                              return ContinuousReaderMode2(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
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
                                onNoNextChapter: onNoNextChapter,
                              );
                          }
                        },
                        errorSource: "chapter-details",
                        webViewUrlProvider: () async {
                          if (chapterRealUrl?.isNotEmpty == true) {
                            return chapterRealUrl;
                          }
                          return await ref
                              .read(mangaBookRepositoryProvider)
                              .getChapterRealUrl(
                                mangaId: mangaId,
                                chapterIndex: initChapterIndexState.value,
                              );
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
