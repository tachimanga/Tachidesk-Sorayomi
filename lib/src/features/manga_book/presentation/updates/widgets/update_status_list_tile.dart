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
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../data/updates/updates_repository.dart';
import '../../../widgets/update_status_summary_sheet_v2.dart';
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

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 6.0),
      leading: running
          ? const MiniCircularProgressIndicator()
          : const Icon(Icons.check_circle_outline),
      horizontalTitleGap: 6,
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
                  "${updateStatus.valueOrNull?.updateChecked.padLeft()}"
                  "/${updateStatus.valueOrNull?.total.padLeft()}",
                  style: context.textTheme.labelMedium,
                ),
              ],
            )
          : Text(
              context.l10n!.update_completed_text(
                  statusMap?.completed?.length ?? 0,
                  statusMap?.failed?.length ?? 0),
              maxLines: 1,
              style: context.textTheme.labelMedium
                  ?.copyWith(overflow: TextOverflow.ellipsis),
            ),
      trailing: running
          ? TextButton(
              onPressed: () async {
                logEvent3("UPDATE:STATUS:CANCEL");
                await ref.read(updatesRepositoryProvider).resetUpdates();
              },
              child: Text(context.l10n!.cancel))
          : GestureDetector(
              onTap: () {
                logEvent3("UPDATE:STATUS:CLOSE");
                ref.read(showUpdateStatusSwitchProvider.notifier).update(false);
              },
              child: const Icon(Icons.close),
            ),
      onTap: () {
        logEvent3("UPDATE:STATUS:TAP");
        showUpdateStatusSummaryBottomSheetV2(context);
      },
    );
  }
}
