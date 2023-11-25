// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/app_sizes.dart';
import '../../../../../../constants/endpoints.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../widgets/server_image.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../chapter_separator.dart';
import '../reader_wrapper.dart';

class ContinuousReaderMode extends HookWidget {
  const ContinuousReaderMode({
    super.key,
    required this.manga,
    required this.chapter,
    this.showSeparator = false,
    this.onPageChanged,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });
  final Manga manga;
  final Chapter chapter;
  final bool showSeparator;
  final ValueSetter<int>? onPageChanged;
  final Axis scrollDirection;
  final bool reverse;
  @override
  Widget build(BuildContext context) {
    final scrollController = useMemoized(() => ItemScrollController());
    final positionsListener = useMemoized(() => ItemPositionsListener.create());
    final currentIndex = useState(
      chapter.read.ifNull() ? 0 : (chapter.lastPageRead).ifNullOrNegative(),
    );
    useEffect(() {
      if (onPageChanged != null) onPageChanged!(currentIndex.value);
      return;
    }, [currentIndex.value]);
    useEffect(() {
      listener() {
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

    final pointCount = useState(0);
    //print("ContinuousReaderMode build point: ${pointCount.value}");
    return ReaderWrapper(
      scrollDirection: scrollDirection,
      chapter: chapter,
      manga: manga,
      currentIndex: currentIndex.value,
      reverse: reverse,
      onChanged: (index) => scrollController.jumpTo(index: index),
      onPrevious: () {
        final ItemPosition itemPosition =
            positionsListener.itemPositions.value.toList().first;
        scrollController.scrollTo(
          index: itemPosition.index,
          duration: kDuration,
          curve: kCurve,
          alignment: itemPosition.itemLeadingEdge + .8,
        );
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
        scrollController.scrollTo(
          index: index,
          duration: kDuration,
          curve: kCurve,
          alignment: alignment,
        );
      },
      child: Listener(
        onPointerDown: (event) {
          pointCount.value = pointCount.value + 1;
          //print("ContinuousReaderMode onPointerDown, point: ${pointCount.value}");
        },
        onPointerUp: (_)  {
          pointCount.value = pointCount.value - 1;
          //print("ContinuousReaderMode onPointerUp, point: ${pointCount.value}");
        },
        onPointerCancel: (_)  {
          pointCount.value = pointCount.value - 1;
          //print("ContinuousReaderMode onPointerCancel, point: ${pointCount.value}");
        },
      child: InteractiveViewer(
        maxScale: 8,
        child: ScrollablePositionedList.separated(
            physics: pointCount.value == 2 ? const NeverScrollableScrollPhysics() : null,
          itemScrollController: scrollController,
          itemPositionsListener: positionsListener,
          initialScrollIndex: chapter.read.ifNull()
              ? 0
              : chapter.lastPageRead.ifNullOrNegative(),
          scrollDirection: scrollDirection,
          reverse: reverse,
          itemCount: chapter.pageCount ?? 0,
          separatorBuilder: (BuildContext context, int index) =>
              showSeparator ? KSizedBox.h16.size : const SizedBox.shrink(),
          itemBuilder: (BuildContext context, int index) {
            final image = ServerImage(
              fit: scrollDirection == Axis.vertical
                  ? BoxFit.fitWidth
                  : BoxFit.fitHeight,
              appendApiToUrl: true,
              imageUrl: MangaUrl.chapterPageWithIndex(
                chapterIndex: "${chapter.index}",
                mangaId: "${manga.id}",
                pageIndex: index.toString(),
              ),
              imageData: chapter.pageData?[index],
              reloadButton: true,
              progressIndicatorBuilder: (_, __, downloadProgress) => Center(
                child: CircularProgressIndicator(
                  value: downloadProgress.progress,
                ),
              ),
              wrapper: (child) => SizedBox(
                height: scrollDirection == Axis.vertical
                    ? context.width
                    : null,
                width: scrollDirection != Axis.vertical
                    ? context.height
                    : null,
                child: child,
              ),
              memCacheWidth: scrollDirection == Axis.vertical
                  ? (context.width * context.devicePixelRatio).toInt()
                  : null,
              memCacheHeight: scrollDirection != Axis.vertical
                  ? (context.height * context.devicePixelRatio).toInt()
                  : null,
            );
            if (index == 0 || index == (chapter.pageCount ?? 1) - 1) {
              final separator = SizedBox(
                width: scrollDirection != Axis.vertical
                    ? context.width * .5
                    : null,
                child: ChapterSeparator(
                  title: index == 0
                      ? context.l10n!.current
                      : context.l10n!.finished,
                  name: (chapter.name ?? context.l10n!.chapterNumber(chapter.chapterNumber ?? 0))
                      + (chapter.scanlator.withPrefix(" • ") ?? ""),
                ),
              );
              final bool reverseDirection =
                  scrollDirection == Axis.horizontal && reverse;

              final topSeparator = Padding(
                padding: EdgeInsets.only(top: max(0, MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.top - 14)),
                child: separator,
              );
              final bottomSeparator = Padding(
                padding: EdgeInsets.only(bottom: max(0, MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom - 14)),
                child: separator,
              );
              return Flex(
                direction: scrollDirection,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: ((index == 0) != reverseDirection)
                    ? [topSeparator, image]
                    : [image, bottomSeparator],
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
