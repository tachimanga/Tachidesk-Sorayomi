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
import '../../../../../settings/presentation/reader/widgets/reader_scroll_animation_tile/reader_scroll_animation_tile.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../../manga_details/controller/manga_details_controller.dart';
import '../../controller/ad_controller.dart';
import '../../controller/reader_controller.dart';
import '../../controller/reader_controller_v2.dart';
import '../../controller/reader_setting_controller.dart';
import '../chapter_loading_widget.dart';
import '../interactive_wrapper.dart';
import '../padding_server_image.dart';
import '../page_action_widget.dart';
import '../page_scroll_physics.dart';
import '../reader_wrapper.dart';

class DoublePageReaderMode extends HookConsumerWidget {
  const DoublePageReaderMode({
    super.key,
    required this.manga,
    required this.initChapterIndexState,
    required this.initChapter,
    required this.readerListData,
    required this.currentRawIndex,
    required this.pageLayout,
    this.onPageChanged,
    this.onNoNextChapter,
    this.reverse = false,
    this.scrollDirection = Axis.horizontal,
  });

  final Manga manga;
  final ValueNotifier<String> initChapterIndexState;
  final Chapter initChapter;
  final ReaderListData readerListData;
  final ValueNotifier<int> currentRawIndex;
  final ReaderPageLayout pageLayout;
  final ValueSetter<PageChangedData>? onPageChanged;
  final AsyncCallback? onNoNextChapter;
  final bool reverse;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // useEffect(() {
    //   log("[Reader2] SinglePageReaderMode2 cretae");
    //   return () {
    //     log("[Reader2] SinglePageReaderMode2 dispose");
    //   };
    // }, []);

    // final skipFirstPage = ref.watch(
    //     readerPageLayoutSkipFirstWithMangaIdProvider(mangaId: "${manga.id}"));

    final rawInitIndex = currentRawIndex.value;
    final uiInitIndex = (rawInitIndex / 2).truncate();

    final scrollController = usePageController(
      initialPage: uiInitIndex,
    );

    final currChapter = useState(initChapter);
    // logger.log("[Reader2] ContinuousReaderMode2 currChapter.state ${currChapter.value.name} "
    //     "initChapter: ${initChapter.name}");

    final currPage = useState(readerListData.pageList[min(
      rawInitIndex,
      readerListData.pageList.length - 1,
    )]);

    final chapterPair = ref.watch(
      getPreviousAndNextChaptersProvider(
        mangaId: "${manga.id}",
        chapterIndex: "${currChapter.value.index}",
      ),
    );
    useEffect(() {
      notifyPageUpdate(currentRawIndex, currPage, currChapter, false);
      if (onNoNextChapter != null) {
        notifyNoNextChapter(currentRawIndex, chapterPair, onNoNextChapter!);
      }
      return;
    }, [currentRawIndex.value]);
    useEffect(() {
      return () {
        notifyPageUpdate(currentRawIndex, currPage, currChapter, true);
      };
    }, []);

    useEffect(() {
      final chapter = readerListData.chapterList.firstWhereOrNull(
          (element) => element.index == currChapter.value.index);
      if (chapter != null) {
        currChapter.value = chapter;
      }
      log("[Reader2] ContinuousReaderMode2 update currChapter to:${chapter?.name}");
      return;
    }, [readerListData]);

    useEffect(() {
      listener() {
        final currentPage = scrollController.page;
        if (currentPage != null) {
          final uiIndex = currentPage.toInt();
          currentRawIndex.value = min(
            uiIndex * 2 + 1,
            readerListData.pageList.length,
          );
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [readerListData]);

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

    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;

    final itemCount = ((readerListData.pageList.length + 1) / 2).truncate() + 1;

    return ReaderWrapper(
      scrollDirection: scrollDirection,
      pageLayout: pageLayout,
      chapter: currChapter.value,
      manga: manga,
      currentIndex: currPage.value.pageIndex,
      reverse: reverse,
      onChanged: (index) {
        final rawIndex =
            readerListData.pageIndexToIndex(currPage.value.chapterIndex, index);
        scrollController.jumpToPage((rawIndex / 2).truncate());
      },
      initChapterIndexState: initChapterIndexState,
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
        child: PageView.builder(
          scrollDirection: scrollDirection,
          physics: pagingEnabled.value && pointCount.value != 2
              ? const CustomPageViewScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          reverse: reverse,
          controller: scrollController,
          allowImplicitScrolling: true,
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            //log("[Reader2]load page $index");
            if (index > 0 && index == itemCount - 1) {
              //log("[Reader2]load ChapterLoadingWidget");
              final page =
                  readerListData.pageList[readerListData.pageList.length - 1];
              final pageChapter = readerListData.chapterMap[page.chapterIndex]!;
              final chapterLoading = ChapterLoadingWidget(
                mangaId: "${pageChapter.mangaId}",
                lastChapterIndex: "${pageChapter.index}",
                scrollDirection: scrollDirection,
                singlePageMode: true,
              );
              return chapterLoading;
            }

            final leftPage = readerListData.pageList[index * 2];
            final rightPage = index * 2 + 1 < readerListData.pageList.length
                ? readerListData.pageList[index * 2 + 1]
                : null;

            final leftImage = buildPageImageWidget(
                leftPage,
                context,
                traceInfo,
                windowPadding,
                currChapter.value,
                reverse ? Alignment.centerLeft : Alignment.centerRight);
            final rightImage = rightPage != null
                ? buildPageImageWidget(
                    rightPage,
                    context,
                    traceInfo,
                    windowPadding,
                    currChapter.value,
                    reverse ? Alignment.centerRight : Alignment.centerLeft)
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

  Widget buildPageImageWidget(
    ReaderPageData page,
    BuildContext context,
    TraceInfo traceInfo,
    EdgeInsets windowPadding,
    Chapter currChapter,
    Alignment alignment,
  ) {
    final imageUrl = MangaUrl.chapterPageWithIndex(
      chapterIndex: "${page.chapterIndex}",
      mangaId: "${manga.id}",
      pageIndex: "${page.pageIndex}",
    );
    final serverImage = ServerImage(
      fit: BoxFit.contain,
      alignment: alignment,
      size: Size.fromHeight(context.height),
      appendApiToUrl: true,
      imageUrl: imageUrl,
      imageData: page.imageData,
      traceInfo: traceInfo,
      chapterUrl: currChapter.realUrl,
      reloadButton: true,
      progressIndicatorBuilder: (context, url, downloadProgress) =>
          CenterCircularProgressIndicator(
        value: downloadProgress.progress,
      ),
    );

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
              imageData: page.imageData,
            ),
          ),
        );
      },
      child: serverImage,
    );
    return image;
  }

  void notifyPageUpdate(
      ValueNotifier<int> currentIndex,
      ValueNotifier<ReaderPageData> currPage,
      ValueNotifier<Chapter> currChapter,
      bool flush) {
    // log("[Reader2] curr currentIndex ${currentIndex.value} ");

    if (readerListData.pageList.length % 2 == 0 &&
        currentIndex.value >= readerListData.pageList.length) {
      return;
    }

    final index = min(
      currentIndex.value,
      readerListData.pageList.length - 1,
    );

    final page = readerListData.pageList[index];
    final pageChapter = readerListData.chapterMap[page.chapterIndex]!;
    currPage.value = page;
    currChapter.value = pageChapter;
    // log("[Reader2] curr page ${page.pageIndex} "
    //     "curr chapter: ${pageChapter.index}");
    if (onPageChanged != null) {
      onPageChanged!(PageChangedData(currPage.value, flush));
    }
  }

  void notifyNoNextChapter(
    ValueNotifier<int> currentIndex,
    Pair<Chapter?, Chapter?>? chapterPair,
    AsyncCallback onNoNextChapter,
  ) {
    //log("[Reader2] reader wrapper ${currentIndex.value}");
    if (chapterPair != null &&
        chapterPair.first == null &&
        currentIndex.value == readerListData.pageList.length) {
      //log("[Reader2] no next chapter");
      onNoNextChapter();
    }
  }
}
