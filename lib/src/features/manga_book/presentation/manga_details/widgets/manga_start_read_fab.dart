// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as ftoast;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/highlighted_container.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../downloads/widgets/download_reward_ad_dialog.dart';
import '../controller/manga_details_controller.dart';

class MangaStartReadFab extends HookConsumerWidget {
  const MangaStartReadFab({
    super.key,
    required this.mangaId,
  });

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstUnreadChapter = ref.watch(
      firstUnreadInFilteredChapterListProvider(mangaId: mangaId),
    );
    final resume = firstUnreadChapter?.lastReadAt.isGreaterThan(0) == true ||
        firstUnreadChapter?.resumeFlag == true;
    return FloatingActionButton.extended(
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
      label: Text(
        resume ? context.l10n!.resume : context.l10n!.start,
      ),
      icon: const Icon(Icons.play_arrow_rounded),
    );
  }
}
