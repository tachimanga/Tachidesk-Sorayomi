// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../controller/downloads_controller.dart';

class DownloadStatusListTile extends HookConsumerWidget {
  const DownloadStatusListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsSocketProvider);
    final runningCount = downloads.valueOrNull?.queue
            ?.where((i) => i.state != "Queued")
            .length ??
        0;
    final totalCount = downloads.valueOrNull?.queue?.length ?? 0;
    final finishCount = downloads.valueOrNull?.finishCount ?? 0;
    final speed = ref.watch(downloadSpeedProvider);

    return ListTile(
      leading: const MiniCircularProgressIndicator(),
      horizontalTitleGap: 6,
      title: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n!.downloading_running_text(
                  runningCount + finishCount, totalCount + finishCount),
              maxLines: 1,
              style: context.textTheme.labelMedium
                  ?.copyWith(overflow: TextOverflow.ellipsis),
            ),
          ),
          Text(
            speed,
            style: context.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
