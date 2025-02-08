// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/enum.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/misc/toast/toast.dart';
import '../../settings/presentation/appearance/controller/date_format_controller.dart';
import '../controller/sync_controller.dart';
import '../data/sync_repository.dart';
import '../domain/sync_model.dart';

class SyncNowTile extends HookConsumerWidget {
  const SyncNowTile({
    super.key,
    this.inSyncWidget = false,
  });

  final bool inSyncWidget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final syncRepository = ref.watch(syncRepositoryProvider);
    final dateFormat = ref.watch(dateFormatPrefProvider);

    final statusValue = ref.watch(syncSocketProvider);
    final status = statusValue.valueOrNull;
    final state = status?.state;
    final counter = status?.counter;
    final lastSyncAt = status?.lastSyncAt;

    if (state == SyncState.running.value) {
      final progress = counter?.toProgressInt() ?? 0;
      return ListTile(
        dense: true,
        contentPadding: inSyncWidget ? EdgeInsets.zero : null,
        leading: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text(
              progress > 0 ? "${counter?.toProgressInt()}%" : "",
              style: context.textTheme.labelSmall?.copyWith(fontSize: 8),
            ),
          ],
        ),
        title: Text(context.l10n!.syncing),
        subtitle: Text(
          counter?.toCounterString() ?? "",
          style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        onTap: () async {
          ref.invalidate(syncSocketProvider);
          // if (inSyncWidget) {
          //   context.pop();
          // }
        },
      );
    }

    if (state == SyncState.fail.value) {
      return ListTile(
        dense: true,
        contentPadding: inSyncWidget ? EdgeInsets.zero : null,
        leading: const Icon(Icons.sync_problem),
        title: Text(context.l10n!.sync_now),
        subtitle: Text(
          localizedErrorMessage(context, dateFormat, status),
          style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
        onTap: () async {
          await triggerSync(syncRepository, toast, context);
        },
      );
    }

    return ListTile(
      dense: true,
      contentPadding: inSyncWidget ? EdgeInsets.zero : null,
      leading: state == SyncState.success.value
          ? const Icon(Icons.cloud_done_outlined)
          : const Icon(Icons.sync),
      title: Text(context.l10n!.sync_now),
      subtitle: lastSyncAt != null
          ? Text(
              context.l10n!.synced_at_time(
                  localizedTimeAgo(context, dateFormat, lastSyncAt)),
              style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
            )
          : null,
      onTap: () async {
        await triggerSync(syncRepository, toast, context);
      },
    );
  }

  String localizedErrorMessage(
      BuildContext context, DateFormatEnum? dateFormat, SyncStatus? status) {
    if (status?.code == "TimeGapException") {
      return context.l10n!.sync_time_tip(
        localizedDateTimeString(
            context, dateFormat, status?.extraInfo?.deviceTime),
        localizedDateTimeString(
            context, dateFormat, status?.extraInfo?.serverTime),
      );
    }
    if (status?.code == "SyncNotEnable") {
      return context.l10n!.sync_not_enable;
    }
    if (status?.code == "LoginRequired") {
      return context.l10n!.login_required;
    }
    return status?.message ?? "";
  }

  String localizedTimeAgo(
      BuildContext context, DateFormatEnum? dateFormat, int? milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds ?? 0);
    final timeAgo = date.convertToLocalizedTimeAgo(
      dateFormat ?? DateFormatEnum.yMMMd,
      context,
    );
    return timeAgo;
  }

  String localizedDateTimeString(
      BuildContext context, DateFormatEnum? dateFormat, int? milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds ?? 0);
    final format = DateFormat(
      (dateFormat ?? DateFormatEnum.yMMMd).code,
      context.currentLocale.toString(),
    );
    format.add_Hms();
    return format.format(date);
  }

  Future<void> triggerSync(
      SyncRepository syncRepository, Toast toast, BuildContext context) async {
    (await AsyncValue.guard(
      () async {
        await syncRepository.syncNow();
      },
    ))
        .showToastOnError(toast);
    // if (inSyncWidget && context.mounted) {
    //   context.pop();
    // }
  }
}
