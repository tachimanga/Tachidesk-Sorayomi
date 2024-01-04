// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/endpoints.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../../widgets/server_image.dart';
import '../../../../../settings/presentation/reader/widgets/reader_scroll_animation_tile/reader_scroll_animation_tile.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../controller/ad_controller.dart';
import '../../controller/reader_controller.dart';
import '../../controller/reader_controller_v2.dart';
import '../chapter_loading_widget.dart';
import '../interactive_wrapper.dart';
import '../page_action_widget.dart';
import '../reader_wrapper.dart';

class SinglePageReaderMode2 extends HookConsumerWidget {
  const SinglePageReaderMode2({
    super.key,
    required this.manga,
    required this.initChapterIndexState,
    required this.initChapter,
    required this.readerListData,
    this.onPageChanged,
    this.reverse = false,
    this.scrollDirection = Axis.horizontal,
  });

  final Manga manga;
  final ValueNotifier<String> initChapterIndexState;
  final Chapter initChapter;
  final ReaderListData readerListData;
  final ValueSetter<ReaderPageData>? onPageChanged;
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
    final initIndex = initChapter.read == true
        ? 0
        : (initChapter.lastPageRead).ifNullOrNegative(0);

    final scrollController = usePageController(
      initialPage: initIndex,
    );
    final currentIndex = useState(initIndex);

    final currChapter = useState(initChapter);
    // logger.log("[Reader2] ContinuousReaderMode2 currChapter.state ${currChapter.value.name} "
    //     "initChapter: ${initChapter.name}");
    final currPage = useState(readerListData.pageList[initIndex]);

    useEffect(() {
      if (currentIndex.value > readerListData.pageList.length - 1) {
        return;
      }
      final page = readerListData.pageList[currentIndex.value];
      final pageChapter = readerListData.chapterMap[page.chapterIndex]!;
      currPage.value = page;
      currChapter.value = pageChapter;
      // log("[Reader2] curr page ${page.pageIndex} "
      //     "curr chapter: ${pageChapter.index}");
      if (onPageChanged != null) onPageChanged!(currPage.value);
      return;
    }, [currentIndex.value]);

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
        if (currentPage != null) currentIndex.value = currentPage.toInt();
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

    final pagingEnabled = useState(true);
    final pointCount = useState(0);
    final isAnimationEnabled =
        ref.read(readerScrollAnimationProvider).ifNull(false);
    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
    return ReaderWrapper(
      scrollDirection: scrollDirection,
      chapter: currChapter.value,
      manga: manga,
      currentIndex: currPage.value.pageIndex,
      reverse: reverse,
      onChanged: (index) => scrollController.jumpToPage(
          readerListData.pageIndexToIndex(currPage.value.chapterIndex, index)),
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
          itemCount: readerListData.totalPageCount + 1,
          itemBuilder: (BuildContext context, int index) {
            //log("[Reader2]load page $index");
            if (index > 0 && index == readerListData.totalPageCount) {
              //log("[Reader2]load ChapterLoadingWidget");
              final page = readerListData.pageList[index - 1];
              final pageChapter = readerListData.chapterMap[page.chapterIndex]!;
              final chapterLoading = ChapterLoadingWidget(
                mangaId: "${pageChapter.mangaId}",
                lastChapterIndex: "${pageChapter.index}",
                scrollDirection: scrollDirection,
                singlePageMode: true,
              );
              return chapterLoading;
            }

            final page = readerListData.pageList[index];
            final imageUrl = MangaUrl.chapterPageWithIndex(
              chapterIndex: "${page.chapterIndex}",
              mangaId: "${manga.id}",
              pageIndex: "${page.pageIndex}",
            );
            final serverImage = ServerImage(
              fit: BoxFit.contain,
              size: Size.fromHeight(context.height),
              appendApiToUrl: true,
              imageUrl: imageUrl,
              imageData: page.imageData,
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
                      chapter: currChapter.value,
                      imageUrl: imageUrl,
                      imageData: page.imageData,
                    ),
                  ),
                );
              },
              child: serverImage,
            );

            return InteractiveWrapper(
              child: image,
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
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({ScrollPhysics? parent})
      : super(parent: parent);

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor)!);
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 50,
    stiffness: 100,
    damping: 0.8,
  );
}
