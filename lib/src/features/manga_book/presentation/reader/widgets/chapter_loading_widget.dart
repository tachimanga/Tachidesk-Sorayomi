// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/server_image.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../../../domain/downloads_queue/downloads_queue_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';
import '../controller/reader_controller.dart';
import '../controller/reader_controller_v2.dart';

class ChapterLoadingWidget extends HookConsumerWidget {
  const ChapterLoadingWidget({
    super.key,
    required this.mangaId,
    required this.lastChapterIndex,
  });

  final String mangaId;
  final String lastChapterIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowPadding =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding;
    final prevNextChapterProvider = useMemoized(
        () => getPreviousAndNextChaptersProvider(
              mangaId: mangaId,
              chapterIndex: lastChapterIndex,
            ),
        []);
    final prevNextChapterPair = ref.watch(prevNextChapterProvider);

    if (prevNextChapterPair?.first == null) {
      //return Text("DONE");
      return const SizedBox.shrink();
    }

    final nextChapterBasic = prevNextChapterPair!.first!;
    final chapterProviderWithIndex = useMemoized(
        () => chapterWithIdProvider(
            mangaId: mangaId, chapterIndex: "${nextChapterBasic.index}"),
        []);
    final nextChapter = ref.watch(chapterProviderWithIndex);

    return nextChapter.showUiWhenData(
      context,
      (data) => const SizedBox.shrink(),// const Text("load succ"),
      refresh: () => ref.refresh(chapterProviderWithIndex),
      wrapper: (child) => Padding(
        padding: EdgeInsets.only(bottom: max(0, windowPadding.bottom - 14)),
        child: SizedBox(
          height: context.width,
          child: child,
        ),
      ),
    );
  }
}
