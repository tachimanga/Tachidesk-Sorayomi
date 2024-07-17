// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../controller/manga_details_controller.dart';

class MangaStartReadIcon extends HookConsumerWidget {
  const MangaStartReadIcon({
    super.key,
    required this.mangaId,
  });

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstUnreadChapter = ref.watch(
      firstUnreadInFilteredChapterListProvider(mangaId: mangaId),
    );
    return IconButton(
      onPressed: firstUnreadChapter != null
          ? () {
              context.push(
                Routes.getReader(
                  "${firstUnreadChapter.mangaId ?? mangaId}",
                  "${firstUnreadChapter.index ?? 0}",
                ),
              );
            }
          : null,
      icon: const Icon(Icons.play_circle_outline),
    );
  }
}
