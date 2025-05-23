// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/endpoints.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../../utils/classes/trace/trace_model.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../../widgets/server_image.dart';
import '../../../../../settings/presentation/reader/widgets/force_enable_scroll_tile/force_enable_scroll_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_long_press_tile/reader_long_press_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_pinch_to_zoom_tile/reader_pinch_to_zoom_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_scroll_animation_tile/reader_scroll_animation_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_use_photo_view_tile/reader_use_photo_view_tile.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../../manga_details/controller/manga_details_controller.dart';
import '../../controller/ad_controller.dart';
import '../../controller/reader_controller.dart';
import '../../controller/reader_controller_v2.dart';
import '../chapter_loading_widget.dart';
import '../interactive_wrapper.dart';
import '../padding_server_image.dart';
import '../page_action_widget.dart';
import '../page_scroll_physics.dart';
import '../reader_wrapper.dart';

class DoublePageReaderModeV2 extends HookConsumerWidget {
  const DoublePageReaderModeV2({
    super.key,
    required this.manga,
    required this.initChapterIndexState,
    required this.initChapter,
    required this.readerListData,
    required this.sharedPageIndex,
    required this.pageLayout,
    required this.visibility,
    this.onPageChanged,
    this.onNoNextChapter,
    this.reverse = false,
    this.scrollDirection = Axis.horizontal,
  });

  final Manga manga;
  final ValueNotifier<String> initChapterIndexState;
  final Chapter initChapter;
  final ReaderListData readerListData;
  final ObjectRef<int> sharedPageIndex;
  final ReaderPageLayout pageLayout;
  final ValueSetter<PageChangedData>? onPageChanged;
  final AsyncCallback? onNoNextChapter;
  final bool reverse;
  final Axis scrollDirection;
  final ValueNotifier<bool> visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initIndex = readerListData
        .pageListIndexToDoublePageListIndex(sharedPageIndex.value);
    final currentIndex = useState(initIndex);
    log("[Reader2] sharedPageIndex:${sharedPageIndex.value} -> currentIndex:${currentIndex.value}");

    final scrollController = usePageController(
      initialPage: initIndex,
    );

    final currChapter = useState(initChapter);

    final currPage = useState(readerListData.doublePageList[min(
      initIndex,
      readerListData.doublePageList.length - 1,
    )]);

    final chapterPair = ref.watch(
      getPreviousAndNextChaptersProvider(
        mangaId: "${manga.id}",
        chapterIndex: "${currChapter.value.index}",
      ),
    );

    final autoScrollIntervalMs = useState<int?>(null);
    final autoScrollDemoMode = useState(false);

    useEffect(() {
      notifyPageUpdate(context, currentIndex, currPage, currChapter);
      notifyNoNextChapter(currentIndex, chapterPair, onNoNextChapter, autoScrollIntervalMs);
      return;
    }, [currentIndex.value]);
    useEffect(() {
      return () {
        if (onPageChanged != null) {
          final page = currPage.value;
          onPageChanged!(PageChangedData(page.second ?? page.first, currChapter.value, true));
        }
      };
    }, []);

    useEffect(() {
      final chapter = readerListData.chapterList.firstWhereOrNull(
          (element) => element.index == currChapter.value.index);
      if (chapter != null) {
        currChapter.value = chapter;
      }
      log("[Reader2] DoublePageReaderMode update currChapter to:${chapter?.name}");
      return;
    }, [readerListData]);

    useEffect(() {
      listener() {
        final currentPage = scrollController.page;
        if (currentPage != null) {
          currentIndex.value = currentPage.toInt();
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, []);

    useEffect(() {
      return () {
        if (bannerAdAliveLinkList.isNotEmpty) {
          final e = bannerAdAliveLinkList.removeAt(0);
          e.close();
        }
        if (chapterAliveLinkList.isNotEmpty) {
          final e = chapterAliveLinkList.removeAt(0);
          e.close();
        }
      };
    }, []);

    final traceInfo = TraceInfo(
      type: TraceType.pageImg.name,
      sourceId: manga.sourceId,
      mangaUrl: manga.realUrl,
    );

    final pagingEnabled = useState(true);
    final pointCount = useState(0);
    final isAnimationEnabled =
        ref.read(readerScrollAnimationProvider).ifNull(false);
    final longPressEnable =
        ref.watch(readerLongPressActionMenuPrefProvider) != false;

    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;

    final enablePhotoView = ref.watch(readerUsePhotoViewPrefProvider);
    final doubleTapZoomIn = ref.watch(readerDoubleTapZoomInProvider) ??
        DBKeys.doubleTapZoomIn.initial;
    final forceEnableScroll = ref.watch(forceEnableScrollPrefProvider);
    Widget? child;
    if (enablePhotoView == true) {
      child = PhotoViewGallery.builder(
        scrollDirection: scrollDirection,
        scrollPhysics: pointCount.value != 2 || forceEnableScroll == true
            ? const CustomPageViewScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        reverse: reverse,
        pageController: scrollController,
        allowImplicitScrolling: true,
        itemCount: readerListData.doublePageList.length + 1,
        builder: (context, index) {
          if (index > 0 && index == readerListData.doublePageList.length) {
            final lastPage = readerListData
                .doublePageList[readerListData.doublePageList.length - 1];
            final pageChapter =
            readerListData.chapterMap[lastPage.first.chapterIndex]!;
            final chapterLoading = ChapterLoadingWidget(
              mangaId: "${pageChapter.mangaId}",
              lastChapterIndex: "${pageChapter.index}",
              scrollDirection: scrollDirection,
              singlePageMode: true,
            );
            return PhotoViewGalleryPageOptions.customChild(
              initialScale: 1.0,
              minScale: 1.0,
              maxScale: 1.0,
              child: chapterLoading,
            );
          }

          final page = readerListData.doublePageList[index];
          final serverImageWithPadding = buildDoublePageWidget(
            page,
            context,
            traceInfo,
            windowPadding,
            currChapter.value,
            longPressEnable,
          );
          return PhotoViewGalleryPageOptions.customChild(
            initialScale: 1.0,
            minScale: 1.0,
            maxScale: 5.0,
            child: serverImageWithPadding,
          );
        },
      );
    }

    return ReaderWrapper(
      visibility: visibility,
      scrollDirection: scrollDirection,
      pageLayout: pageLayout,
      chapter: currChapter.value,
      manga: manga,
      currentIndex: (currPage.value.second ?? currPage.value.first).pageIndex,
      reverse: reverse,
      onChanged: (pageIndex) {
        final page = currPage.value.second ?? currPage.value.first;
        final index =
            readerListData.doublePageIndexToIndex(page.chapterIndex, pageIndex);
        scrollController.jumpToPage(index);
      },
      initChapterIndexState: initChapterIndexState,
      autoScrollIntervalMs: autoScrollIntervalMs,
      autoScrollDemoMode: autoScrollDemoMode,
      onPrevious: () => scrollController.previousPage(
        duration: isAnimationEnabled ? kDuration : kInstantDuration,
        curve: kCurve,
      ),
      onNext: () => scrollController.nextPage(
        duration: isAnimationEnabled ? kDuration : kInstantDuration,
        curve: kCurve,
      ),
      child: Listener(
        onPointerDown: (event) {
          pointCount.value = pointCount.value + 1;
        },
        onPointerUp: (_) {
          pointCount.value = pointCount.value - 1;
        },
        onPointerCancel: (_) {
          pointCount.value = pointCount.value - 1;
        },
        child: child ?? PageView.builder(
          scrollDirection: scrollDirection,
          physics: pagingEnabled.value && pointCount.value != 2
              ? const CustomPageViewScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          reverse: reverse,
          controller: scrollController,
          allowImplicitScrolling: true,
          itemCount: readerListData.doublePageList.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index > 0 && index == readerListData.doublePageList.length) {
              final lastPage = readerListData
                  .doublePageList[readerListData.doublePageList.length - 1];
              final pageChapter =
                  readerListData.chapterMap[lastPage.first.chapterIndex]!;
              final chapterLoading = ChapterLoadingWidget(
                mangaId: "${pageChapter.mangaId}",
                lastChapterIndex: "${pageChapter.index}",
                scrollDirection: scrollDirection,
                singlePageMode: true,
              );
              return chapterLoading;
            }

            final page = readerListData.doublePageList[index];
            final serverImageWithPadding = buildDoublePageWidget(
              page,
              context,
              traceInfo,
              windowPadding,
              currChapter.value,
              longPressEnable,
            );
            return InteractiveWrapper(
              child: serverImageWithPadding,
              onScaleChanged: (scale) {
                // Disable paging when image is zoomed-in
                pagingEnabled.value = scale <= 1.0;
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildDoublePageWidget(
    ReaderDoublePageData page,
    BuildContext context,
    TraceInfo traceInfo,
    EdgeInsets windowPadding,
    Chapter currChapter,
    bool longPressEnable,
  ) {
    final leftPage = page.first;
    final rightPage = page.second;

    if (page.singlePage) {
      final serverImage = buildPageImageWidget(
        leftPage,
        context,
        traceInfo,
        windowPadding,
        currChapter,
        Alignment.center,
        longPressEnable,
      );
      return PaddingServerImage(
        scrollDirection: scrollDirection,
        contextSize: context.mediaQuerySize,
        mangaId: manga.id.toString(),
        serverImage: serverImage,
      );
    }

    final leftImage = buildPageImageWidget(
      leftPage,
      context,
      traceInfo,
      windowPadding,
      currChapter,
      reverse ? Alignment.centerLeft : Alignment.centerRight,
      longPressEnable,
    );
    final rightImage = rightPage != null
        ? buildPageImageWidget(
            rightPage,
            context,
            traceInfo,
            windowPadding,
            currChapter,
            reverse ? Alignment.centerRight : Alignment.centerLeft,
            longPressEnable,
          )
        : const SizedBox.shrink();

    final serverImageWithPadding = PaddingServerImage(
      scrollDirection: scrollDirection,
      contextSize: context.mediaQuerySize,
      mangaId: manga.id.toString(),
      serverImage: Row(
        children: reverse
            ? [
                Expanded(child: rightImage),
                Expanded(child: leftImage),
              ]
            : [
                Expanded(child: leftImage),
                Expanded(child: rightImage),
              ],
      ),
    );
    return serverImageWithPadding;
  }

  Widget buildPageImageWidget(
    ReaderPageData page,
    BuildContext context,
    TraceInfo traceInfo,
    EdgeInsets windowPadding,
    Chapter currChapter,
    Alignment alignment,
    bool longPressEnable,
  ) {
    final imageUrl = MangaUrl.chapterPageWithIndex(
      chapterIndex: "${page.chapterIndex}",
      mangaId: "${manga.id}",
      pageIndex: "${page.pageIndex}",
    );
    const decodeFactor = 1;
    final serverImage = ServerImage(
      fit: BoxFit.contain,
      alignment: alignment,
      size: Size.fromHeight(context.height),
      appendApiToUrl: true,
      imageUrl: imageUrl,
      imageData: page.imageData,
      traceInfo: traceInfo,
      chapterId: currChapter.id,
      reloadButton: true,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CenterCircularProgressIndicator(
        value: downloadProgress.progress,
      ),
      maxDecodeWidth: scrollDirection != Axis.vertical
          ? context.width * decodeFactor
          : null,
      maxDecodeHeight: scrollDirection == Axis.vertical
          ? context.height * decodeFactor
          : null,
    );
    if (!longPressEnable) {
      return serverImage;
    }
    final image = GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: context.theme.cardColor,
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: windowPadding.bottom),
            child: PageActionWidget(
              manga: manga,
              chapter: currChapter,
              imageUrl: imageUrl,
              page: page,
              doublePageMode: true,
            ),
          ),
        );
      },
      child: serverImage,
    );
    return image;
  }

  void notifyPageUpdate(
      BuildContext context,
      ValueNotifier<int> currentIndex,
      ValueNotifier<ReaderDoublePageData> currPage,
      ValueNotifier<Chapter> currChapter) {
    if (currentIndex.value > readerListData.doublePageList.length - 1) {
      return;
    }

    sharedPageIndex.value =
        readerListData.doublePageListIndexToPageListIndex(currentIndex.value);
    log("[Reader2] currentIndex:${currentIndex.value} -> sharedPageIndex:${sharedPageIndex.value}");

    final page = readerListData.doublePageList[currentIndex.value];
    final pageChapter = readerListData.chapterMap[page.first.chapterIndex]!;
    if (context.mounted) {
      currPage.value = page;
      currChapter.value = pageChapter;
    }
    // log("[Reader2] curr page ${page.pageIndex} "
    //     "curr chapter: ${pageChapter.index}");
    if (onPageChanged != null) {
      onPageChanged!(PageChangedData(page.second ?? page.first, pageChapter, false));
    }
  }

  void notifyNoNextChapter(
    ValueNotifier<int> currentIndex,
    Pair<Chapter?, Chapter?>? chapterPair,
    AsyncCallback? onNoNextChapter,
    ValueNotifier<int?> autoScrollIntervalMs,
  ) {
    //log("[Reader2] reader wrapper ${currentIndex.value}");
    if (chapterPair != null &&
        chapterPair.first == null &&
        currentIndex.value == readerListData.doublePageList.length) {
      //log("[Reader2] no next chapter");
      if (onNoNextChapter != null) {
        onNoNextChapter();
      }
      autoScrollIntervalMs.value = null;
    }
  }
}
