// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../data/downloads/downloads_repository.dart';

class DownloadsTaskButton extends ConsumerWidget {
  const DownloadsTaskButton({
    super.key,
    required this.status,
    required this.enable,
  });

  final String status;
  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    if (status == "Stopped" || status == "Error") {
      return FilledButton.icon(
        onPressed: () async {
          if (!enable) {
            return;
          }
          (await AsyncValue.guard(
                  ref.read(downloadsRepositoryProvider).startDownloads))
              .showToastOnError(toast);
        },
        label: Text(context.l10n!.resume),
        icon: const Icon(Icons.play_arrow),
      );
    } else {
      return FilledButton.icon(
        onPressed: enable
            ? () async {
                (await AsyncValue.guard(
                        ref.read(downloadsRepositoryProvider).stopDownloads))
                    .showToastOnError(toast);
              }
            : null,
        label: Text(context.l10n!.pause),
        icon: const Icon(Icons.pause_rounded),
      );
    }
  }
}
