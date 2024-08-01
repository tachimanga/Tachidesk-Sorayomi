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

import '../../../../../../constants/enum.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../domain/chapter/chapter_model.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../controller/reader_controller_v2.dart';
import '../../controller/reader_setting_controller.dart';
import 'double_page_reader_mode_v2.dart';
import 'single_page_reader_mode_v2.dart';

class PageReaderMode extends HookConsumerWidget {
  const PageReaderMode({
    super.key,
    required this.manga,
    required this.initChapterIndexState,
    required this.initChapter,
    required this.readerListData,
    this.onPageChanged,
    this.onNoNextChapter,
    this.reverse = false,
    this.scrollDirection = Axis.horizontal,
  });

  final Manga manga;
  final ValueNotifier<String> initChapterIndexState;
  final Chapter initChapter;
  final ReaderListData readerListData;
  final ValueSetter<PageChangedData>? onPageChanged;
  final AsyncCallback? onNoNextChapter;
  final bool reverse;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageLayout =
        ref.watch(readerPageLayoutWithMangaIdProvider(mangaId: "${manga.id}"));
    final doublePage = pageLayout == ReaderPageLayout.doublePage ||
        (pageLayout == ReaderPageLayout.automatic &&
            context.width > context.height);
    log("[ReaderV2] PageReaderMode build effectPageLayout:$pageLayout");


    final lastPageRead = max(0,
        min(initChapter.lastPageRead ?? 0, (initChapter.pageCount ?? 1) - 1));
    final initIndex = initChapter.read == true ? 0 : lastPageRead;

    final sharedPageIndex = useRef(initIndex);

    return doublePage
        ? DoublePageReaderModeV2(
            manga: manga,
            initChapterIndexState: initChapterIndexState,
            initChapter: initChapter,
            readerListData: readerListData,
            sharedPageIndex: sharedPageIndex,
            pageLayout: pageLayout,
            onPageChanged: onPageChanged,
            onNoNextChapter: onNoNextChapter,
            reverse: reverse,
            scrollDirection: scrollDirection,
          )
        : SinglePageReaderMode2(
            manga: manga,
            initChapterIndexState: initChapterIndexState,
            initChapter: initChapter,
            readerListData: readerListData,
            sharedPageIndex: sharedPageIndex,
            pageLayout: pageLayout,
            onPageChanged: onPageChanged,
            onNoNextChapter: onNoNextChapter,
            reverse: reverse,
            scrollDirection: scrollDirection,
          );
  }
}
