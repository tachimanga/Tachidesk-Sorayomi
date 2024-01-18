// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:octo_image/octo_image.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/app_sizes.dart';
import '../../../../../../constants/endpoints.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart' as logger;
import '../../../../../../widgets/server_image.dart';
import '../../../../../settings/presentation/reader/widgets/reader_scroll_animation_tile/reader_scroll_animation_tile.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../controller/ad_controller.dart';
import '../../controller/reader_controller.dart';
import '../../controller/reader_controller_v2.dart';
import '../page_action_widget.dart';
import '../chapter_loading_widget.dart';
import '../chapter_separator.dart';
import '../interactive_wrapper.dart';
import '../reader_wrapper.dart';

class ContinuousReaderMode2 extends HookConsumerWidget {
  const ContinuousReaderMode2({
    super.key,
    required this.manga,
    required this.initChapterIndexState,
    required this.initChapter,
    required this.readerListData,
    this.showSeparator = false,
    this.onPageChanged,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });
  final Manga manga;
  final ValueNotifier<String> initChapterIndexState;
  final Chapter initChapter;
  final ReaderListData readerListData;
  final bool showSeparator;
  final ValueSetter<ReaderPageData>? onPageChanged;
  final Axis scrollDirection;
  final bool reverse;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // useEffect(() {
    //   print("[Reader2] ContinuousReaderMode2 cretae");
    //   return () {
    //     print("[Reader2] ContinuousReaderMode2 dispose");
    //   };
    // }, []);
    final initIndex = initChapter.read == true
        ? 0
        : (initChapter.lastPageRead).ifNullOrNegative(0);
    final currentIndex = useState(initIndex);
    final currChapter = useState(initChapter);
    // logger.log("[Reader2] ContinuousReaderMode2 currChapter.state ${currChapter.value.name} "
    //     "initChapter: ${initChapter.name}");
    final currPage = useState(readerListData.pageList[initIndex]);

    final scrollController = useMemoized(() => ItemScrollController());
    final positionsListener = useMemoized(() => ItemPositionsListener.create());
    final imageSizeCache = useMemoized(() => ImageSizeCache());

    useEffect(() {
      final page = readerListData.pageList[currentIndex.value];
      final pageChapter = readerListData.chapterMap[page.chapterIndex]!;
      currPage.value = page;
      currChapter.value = pageChapter;
      // logger.log("[Reader2] curr page ${page.pageIndex} "
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
      logger.log("[Reader2] ContinuousReaderMode2 update currChapter to:${chapter?.name}");
      return;
    }, [readerListData]);

    useEffect(() {
      listener() {
        // The position of items that are at least partially visible in the viewport
        final positions = positionsListener.itemPositions.value.toList();
        if (positions.isSingletonList) {
          currentIndex.value = (positions.first.index);
        } else {
          final newPositions = positions.where((ItemPosition position) =>
              position.itemTrailingEdge.liesBetween());
          if (newPositions.isBlank) return;
          currentIndex.value = newPositions
              .reduce((ItemPosition max, ItemPosition position) =>
                  position.itemTrailingEdge > max.itemTrailingEdge
                      ? position
                      : max)
              .index;
        }
      }

      positionsListener.itemPositions.addListener(listener);
      return () => positionsListener.itemPositions.removeListener(listener);
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

    final isAnimationEnabled =
        ref.read(readerScrollAnimationProvider).ifNull(false);

    final pointCount = useState(0);
    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
    //print("ContinuousReaderMode build point: ${pointCount.value}");
    return ReaderWrapper(
      scrollDirection: scrollDirection,
      chapter: currChapter.value,
      manga: manga,
      currentIndex: currPage.value.pageIndex,
      reverse: reverse,
      onChanged: (index) => scrollController.jumpTo(
          index: readerListData.pageIndexToIndex(
              currPage.value.chapterIndex, index)),
      initChapterIndexState: initChapterIndexState,
      onPrevious: () {
        final ItemPosition itemPosition =
            positionsListener.itemPositions.value.toList().first;
        if (isAnimationEnabled) {
          scrollController.scrollTo(
            index: itemPosition.index,
            duration: kDuration,
            curve: kCurve,
            alignment: itemPosition.itemLeadingEdge + .8,
          );
        } else {
          scrollController.jumpTo(
            index: itemPosition.index,
            alignment: itemPosition.itemLeadingEdge + .8,
          );
        }
      },
      onNext: () {
        ItemPosition itemPosition = positionsListener.itemPositions.value.first;
        final int index;
        final double alignment;
        if (itemPosition.itemTrailingEdge > 1) {
          index = itemPosition.index;
          alignment = itemPosition.itemLeadingEdge - .8;
        } else {
          index = itemPosition.index + 1;
          alignment = 0;
        }
        if (isAnimationEnabled) {
          scrollController.scrollTo(
            index: index,
            duration: kDuration,
            curve: kCurve,
            alignment: alignment,
          );
        } else {
          scrollController.jumpTo(
            index: index,
            alignment: alignment,
          );
        }
      },
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
          child: InteractiveWrapper(
            child: ScrollablePositionedList.separated(
              physics: pointCount.value == 2
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemScrollController: scrollController,
              itemPositionsListener: positionsListener,
              initialScrollIndex: initIndex,
              scrollDirection: scrollDirection,
              reverse: reverse,
              itemCount: readerListData.totalPageCount,
              separatorBuilder: (BuildContext context, int index) =>
                  showSeparator ? KSizedBox.h16.size : const SizedBox.shrink(),
              itemBuilder: (BuildContext context, int index) {
                final page = readerListData.pageList[index];
                final pageChapter =
                    readerListData.chapterMap[page.chapterIndex]!;
                final imageUrl = MangaUrl.chapterPageWithIndex(
                  chapterIndex: "${page.chapterIndex}",
                  mangaId: "${manga.id}",
                  pageIndex: "${page.pageIndex}",
                );
                final serverImage = ServerImage(
                  fit: scrollDirection == Axis.vertical
                      ? BoxFit.fitWidth
                      : BoxFit.fitHeight,
                  appendApiToUrl: true,
                  imageUrl: imageUrl,
                  imageData: page.imageData,
                  reloadButton: true,
                  progressIndicatorBuilder: (_, __, downloadProgress) => Center(
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                    ),
                  ),
                  wrapper: (child) => SizedBox(
                    height: scrollDirection == Axis.vertical
                        ? context.height * .7
                        : null,
                    width: scrollDirection != Axis.vertical
                        ? context.width * .7
                        : null,
                    child: child,
                  ),
                  memCacheWidth: scrollDirection == Axis.vertical
                      ? (context.width * context.devicePixelRatio).toInt()
                      : null,
                  memCacheHeight: scrollDirection != Axis.vertical
                      ? (context.height * context.devicePixelRatio).toInt()
                      : null,
                  imageSizeCache: imageSizeCache,
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
                if (page.pageIndex == 0 ||
                    page.pageIndex == (pageChapter.pageCount ?? 1) - 1) {
                  final separator = SizedBox(
                    width: scrollDirection != Axis.vertical
                        ? context.width * .5
                        : null,
                    child: ChapterSeparator(
                      title: page.pageIndex == 0
                          ? context.l10n!.current
                          : context.l10n!.finished,
                      name: (pageChapter.name ??
                              context.l10n!.chapterNumber(
                                  pageChapter.chapterNumber ?? 0)) +
                          (pageChapter.scanlator.withPrefix(" • ") ?? ""),
                    ),
                  );

                  final chapterLoading = ChapterLoadingWidget(
                    mangaId: "${pageChapter.mangaId}",
                    lastChapterIndex: "${pageChapter.index}",
                    scrollDirection: scrollDirection,
                    singlePageMode: false,
                  );

                  if (scrollDirection == Axis.horizontal) {
                    if (reverse == false) {
                      // separator - images - separator - chapterLoading
                      if (pageChapter.pageCount == 1) {
                        return Flex(
                          direction: scrollDirection,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            separator,
                            image,
                            separator,
                            chapterLoading
                          ],
                        );
                      }
                      return Flex(
                        direction: scrollDirection,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: page.pageIndex == 0
                            ? [separator, image]
                            : [image, separator, chapterLoading],
                      );
                    } else {
                      // chapterLoading - separator - images - separator
                      if (pageChapter.pageCount == 1) {
                        return Flex(
                          direction: scrollDirection,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            chapterLoading,
                            separator,
                            image,
                            separator
                          ],
                        );
                      }
                      return Flex(
                        direction: scrollDirection,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: page.pageIndex == 0
                            ? [image, separator]
                            : [chapterLoading, separator, image],
                      );
                    }
                  }

                  final topSeparator = index == 0
                      ? Padding(
                          padding: EdgeInsets.only(
                              top: max(0, windowPadding.top - 14)),
                          child: separator,
                        )
                      : separator;
                  final bottomSeparator =
                      index == readerListData.totalPageCount - 1
                          ? Padding(
                              padding: EdgeInsets.only(
                                  bottom: max(0, windowPadding.bottom - 14)),
                              child: separator,
                            )
                          : separator;

                  if (pageChapter.pageCount == 1) {
                    return Flex(
                      direction: scrollDirection,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        topSeparator,
                        image,
                        bottomSeparator,
                        chapterLoading
                      ],
                    );
                  }
                  return Flex(
                    direction: scrollDirection,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: page.pageIndex == 0
                        ? [topSeparator, image]
                        : [image, bottomSeparator, chapterLoading],
                  );
                } else {
                  return image;
                }
              },
            ),
          )),
    );
  }
}
