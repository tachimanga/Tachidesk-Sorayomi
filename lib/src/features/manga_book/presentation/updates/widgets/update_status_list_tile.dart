// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../data/updates/updates_repository.dart';
import '../../../widgets/update_status_summary_sheet_v2.dart';
import 'update_status_summary_sheet_v3.dart';
import '../controller/update_controller.dart';

class UpdateStatusListTile extends HookConsumerWidget {
  const UpdateStatusListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(updateFinalStatusProvider);
    final running = updateStatus.valueOrNull?.running == true;
    final statusMap = updateStatus.valueOrNull?.statusMap;
    final skipCount = (updateStatus.valueOrNull?.failedInfo?.values ?? [])
        .where((e) => e.errorCode != JobErrorCode.UPDATE_FAILED)
        .length;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 6.0),
      leading: running
          ? const MiniCircularProgressIndicator()
          : const Icon(Icons.check_circle_outline),
      horizontalTitleGap: 8,
      title: running
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n!.update_running_text(
                        statusMap?.running?.firstOrNull?.title ?? ""),
                    maxLines: 1,
                    style: context.textTheme.labelMedium
                        ?.copyWith(overflow: TextOverflow.ellipsis),
                  ),
                ),
                Text(
                  "${((statusMap?.completed?.length ?? 0) + (statusMap?.failed?.length ?? 0) - skipCount).padLeft()}"
                  "/${((updateStatus.valueOrNull?.numberOfJobs ?? 0) - skipCount).padLeft()}",
                  style: context.textTheme.labelMedium,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n!.update_completed_label,
                  style: context.textTheme.labelMedium
                      ?.copyWith(overflow: TextOverflow.ellipsis),
                ),
                Text(
                  context.l10n!.update_completed_text_v2(
                    statusMap?.completed?.length ?? 0,
                    skipCount,
                    (statusMap?.failed?.length ?? 0) - skipCount,
                  ),
                  style: context.textTheme.labelSmall
                      ?.copyWith(overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
      trailing: running
          ? TextButton(
              onPressed: () async {
                logEvent3("UPDATE:STATUS:CANCEL");
                await ref.read(updatesRepositoryProvider).resetUpdates();
              },
              child: Text(context.l10n!.cancel))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    logEvent3("UPDATE:STATUS:CLOSE");
                    ref
                        .read(showUpdateStatusSwitchProvider.notifier)
                        .update(false);
                  },
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
                SizedBox(width: 2),
              ],
            ),
      onTap: () {
        logEvent3("UPDATE:STATUS:TAP");
        showUpdateStatusSummaryBottomSheetV3(context);
      },
    );
  }
}
