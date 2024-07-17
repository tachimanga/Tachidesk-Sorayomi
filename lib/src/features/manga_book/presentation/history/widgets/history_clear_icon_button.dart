// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../data/manga_book_repository.dart';

class HistoryClearIconButton extends HookConsumerWidget {
  const HistoryClearIconButton({
    super.key,
    required this.refresh,
  });

  final VoidCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    return PopupMenuButton(
      shape: RoundedRectangleBorder(
        borderRadius: KBorderRadius.r16.radius,
      ),
      icon: const Icon(Icons.delete_rounded),
      itemBuilder: (context) => <PopupMenuEntry>[
        PopupMenuItem(
          onTap: () async {
            logEvent3("HISTORY:CLEAR:1H");
            DateTime now = DateTime.now();
            DateTime oneHourAgo = now.subtract(const Duration(hours: 1));
            int lastReadAt = oneHourAgo.millisecondsSinceEpoch ~/ 1000;
            await _clearHistory(context, ref, toast, lastReadAt);
          },
          child: Text(context.l10n!.clear_last_hour),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("HISTORY:CLEAR:1D");
            DateTime now = DateTime.now();
            DateTime todayStart = DateTime(now.year, now.month, now.day);
            int lastReadAt = todayStart.millisecondsSinceEpoch ~/ 1000;
            await _clearHistory(context, ref, toast, lastReadAt);
          },
          child: Text(context.l10n!.clear_today),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("HISTORY:CLEAR:2D");
            DateTime now = DateTime.now();
            DateTime yesterday = now.subtract(const Duration(days: 1));
            DateTime yesterdayStart =
                DateTime(yesterday.year, yesterday.month, yesterday.day);
            int lastReadAt = yesterdayStart.millisecondsSinceEpoch ~/ 1000;
            await _clearHistory(context, ref, toast, lastReadAt);
          },
          child: Text(context.l10n!.clear_today_and_yesterday),
        ),
        PopupMenuItem(
          onTap: () async {
            logEvent3("HISTORY:CLEAR:ALL");
            await _clearHistory(context, ref, toast, -1);
          },
          child: Text(context.l10n!.clear_all_time),
        ),
      ],
    );
  }

  Future<void> _clearHistory(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    int lastReadAt,
  ) async {
    log("[History]clearHistory lastReadAt:$lastReadAt");
    (await AsyncValue.guard(() async {
      await ref.read(mangaBookRepositoryProvider).clearHistory(lastReadAt);
      refresh();
    }))
        .showToastOnError(toast);
  }
}
