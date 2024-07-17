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

class MangaStartReadButton extends HookConsumerWidget {
  const MangaStartReadButton({
    super.key,
    required this.mangaId,
    required this.enable,
  });

  final String mangaId;
  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstUnreadChapter = ref.watch(
      firstUnreadInFilteredChapterListProvider(mangaId: mangaId),
    );
    final resume = firstUnreadChapter?.lastReadAt.isGreaterThan(0) == true ||
        firstUnreadChapter?.resumeFlag == true;
    return FilledButton(
      onPressed: enable && firstUnreadChapter != null
          ? () {
              context.push(
                Routes.getReader(
                  "${firstUnreadChapter.mangaId ?? mangaId}",
                  "${firstUnreadChapter.index ?? 0}",
                ),
              );
            }
          : null,
      child: Text(
        resume
            ? context.l10n!
                .continue_reading_chapter(firstUnreadChapter?.name ?? "")
            : context.l10n!.start_reading,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
