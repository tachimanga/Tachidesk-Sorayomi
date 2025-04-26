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
import '../../../../utils/log.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/common_error_widget.dart';
import '../../../browse_center/domain/browse/browse_model.dart';
import '../../../settings/presentation/appearance/controller/theme_controller.dart';
import '../../../settings/presentation/reader/widgets/reader_keep_screen_on/reader_keep_screen_on_tile.dart';
import '../../../settings/presentation/reader/widgets/reader_mode_tile/reader_mode_tile.dart';
import '../../../settings/presentation/reader/widgets/show_status_bar_tile/show_status_bar_tile.dart';
import '../../../settings/presentation/reader/widgets/swipe_right_back_tile/swipe_right_back_tile.dart';
import '../../../settings/presentation/security/controller/security_controller.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter_patch/chapter_put_model.dart';
import '../manga_details/controller/manga_details_controller.dart';
import '../updates/controller/update_controller.dart';
import 'controller/reader_controller.dart';
import 'controller/reader_controller_v2.dart';
import 'widgets/reader_mode/continuous_reader_mode_v2.dart';
import 'widgets/reader_mode/page_reader_mode.dart';

var readDuration = 0;

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
    final visibility = useState(false);

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
    final autoDeleteService = ref.read(autoDeleteProvider.notifier);

    final manga = ref.watch(mangaProvider);
    final chapter = ref.watch(chapterProviderWithIndex);
    //logger.log("[Reader2] ReaderScreen2.chapter ${chapter.valueOrNull?.name}, index:${chapter.valueOrNull?.index}");

    final globalReaderMode = ref.watch(readerModeKeyProvider) ?? ReaderMode.webtoon;
    final mangaReaderMode = manga.valueOrNull?.meta?.readerMode ?? ReaderMode.defaultReader;
    final readerMode = mangaReaderMode == ReaderMode.defaultReader
        ? globalReaderMode : mangaReaderMode;

    final incognito = ref.read(incognitoModePrefProvider) == true;

    useEffect(() {
      TraceRef.put(manga.valueOrNull?.sourceId, mangaId);
      return;
    }, [manga]);

    final mangaNotifier = ref.read(mangaProvider.notifier);
    final chapterListProvider = mangaChapterListProvider(mangaId: mangaId);
    final chapterListNotifier = ref.read(chapterListProvider.notifier);

    final updatePageNotifier = ref.watch(updatePageRefreshChapterSignalProvider.notifier);

    final keepScreenOn = ref.read(readerKeepScreenOnPrefProvider) == true;
    useEffect(() {
      if (keepScreenOn) {
        pipe.invokeMethod("SCREEN_ON", "1");
      }
      return;
    }, []);

    final showStatusBar = ref.watch(showStatusBarModeProvider);
    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: visibility.value ? SystemUiOverlay.values : [
            if (showStatusBar == true) SystemUiOverlay.top,
          ]
      );
      return;
    }, [visibility.value]);

    useEffect(() {
      return () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
        pipe.invokeMethod("SCREEN_ON", "0");
      };
    }, []);

    final readDurationTimer = useRef<Timer?>(null);
    useEffect(() {
      readDuration = 0;
      readDurationTimer.value = Timer.periodic(
        const Duration(seconds: 5),
            (timer) {
          if (WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
            readDuration = readDuration + 5;
          }
        },
      );
      return () {
        readDurationTimer.value?.cancel();
      };
    }, []);

    final debounce = useRef<Timer?>(null);
    final onPageChanged2 = useCallback<AsyncValueSetter<PageChangedData>>(
      (PageChangedData pageChangedData) async {
        final currentPage = pageChangedData.currentPage;
        final currChapter = pageChangedData.currentChapter;
        final flush = pageChangedData.flush;
        logger.log("[Reader2] onPageChanged currChapter:${currChapter.name}, "
            "currentPage:${currentPage.pageIndex}, flush:$flush");
        updateLastRead() async {
          final lifecycleState = WidgetsBinding.instance.lifecycleState;
          if (lifecycleState != AppLifecycleState.resumed) {
            logger.log("skip updateLastRead, app in bg:$lifecycleState");
            return;
          }
          final isFinalPage = currentPage.pageIndex + 1 >=
              currChapter.pageCount.ifNullOrNegative(0);
          logger.log("[Reader2] updateLastRead index:${currentPage.pageIndex} "
              "isFinalPage:$isFinalPage currChapter.read:${currChapter.read}");
          final duration = readDuration;
          readDuration = 0;
          final input = ChapterModifyInput(
            mangaId: currChapter.mangaId,
            chapterId: currentPage.chapterId,
            lastPageRead: isFinalPage ? 0 : currentPage.pageIndex,
            readDuration: duration,
            read: currChapter.read == true || isFinalPage,
            incognito: incognito,
          );
          await AsyncValue.guard(
                  () => mangaBookRepository.chapterModify(input: input));
          if (flush) {
            chapterListNotifier.refreshSilently();
          }
          if (isFinalPage || flush) {
            updatePageNotifier.update(currentPage.chapterId ?? 0);
          }
          if (isFinalPage && currChapter.downloaded == true) {
            autoDeleteService.addToDeleteList(currChapter);
          }
        }

        final finalDebounce = debounce.value;
        if ((finalDebounce?.isActive).ifNull()) {
          finalDebounce?.cancel();
        }
        final isFinalPage = currentPage.pageIndex + 1 >=
            currChapter.pageCount.ifNullOrNegative(0);
        if (isFinalPage || flush) {
          updateLastRead();
        } else {
          debounce.value = Timer(const Duration(seconds: 2), updateLastRead);
        }
        return;
      },
      [],
    );

    final AsyncCallback? onNoNextChapter = magic.c3 ? () async {
      logger.log("[Reader2] no next chapter");
      pipe.invokeMethod("READER:NO_CHAPTER_AD");
    } : null;

    useRouteObserver(routeObserver, didPop: () {
      logger.log("ReaderScreen did pop");

      // trigger auto delete
      autoDeleteService.triggerDelete();

      mangaNotifier.refreshSilently();
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
                                visibility: visibility,
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
                                visibility: visibility,
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
                                visibility: visibility,
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
                                visibility: visibility,
                              );
                            case ReaderMode.singleHorizontalLTR:
                              return PageReaderMode(
                                manga: data,
                                initChapterIndexState: initChapterIndexState,
                                initChapter: chapterData,
                                readerListData: readerListData,
                                onPageChanged: onPageChanged2,
                                onNoNextChapter: onNoNextChapter,
                                visibility: visibility,
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
                                visibility: visibility,
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
                                visibility: visibility,
                              );
                          }
                        },
                        errorSource: "chapter-details",
                        mangaId: mangaId,
                        urlFetchInput: UrlFetchInput.ofChapterIndex(
                          int.tryParse(mangaId),
                          int.tryParse(initChapterIndexState.value),
                        ),
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
