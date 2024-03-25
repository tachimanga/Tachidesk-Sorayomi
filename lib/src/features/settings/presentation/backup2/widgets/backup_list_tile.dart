// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/date_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../domain/backup/backup_model.dart';
import '../../appearance/controller/date_format_controller.dart';
import '../controller/backup_controller.dart';

class BackupListTile extends ConsumerWidget {
  const BackupListTile({
    super.key,
    required this.backupItem,
    required this.refresh,
    required this.loadingState,
    required this.onConfirm,
    required this.msgMap,
  });
  final BackupItem backupItem;
  final AsyncCallback refresh;
  final ValueNotifier<bool> loadingState;
  final VoidCallback onConfirm;
  final Map<String, String> msgMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatLocalizedDateTime(dateFormatPref, context, backupItem.createAt ?? 0),
                  style: context.textTheme.titleSmall,
                ),
                Text(
                    "${buildBackupTitle(context, backupItem)} "
                    "${formatFileSize(backupItem.size ?? 0)}",
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.r16.radius,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: loadingState.value ? null : onConfirm,
                child: Text(context.l10n!.restoreBackup),
              ),
              PopupMenuItem(
                onTap: () async {
                  if (loadingState.value) {
                    return;
                  }
                  pipe.invokeMethod("LogEvent", "BACKUP:EXPORT");
                  loadingState.value = true;
                  (await AsyncValue.guard(() async {
                    await ref
                        .read(backupActionProvider)
                        .exportBackup(backupItem.name ?? "", msgMap);
                    await refresh();
                  }))
                      .showToastOnError(toast);
                  loadingState.value = false;
                },
                child: Text(context.l10n!.exportBackup),
              ),
              PopupMenuItem(
                onTap: () async {
                  if (loadingState.value) {
                    return;
                  }
                  pipe.invokeMethod("LogEvent", "BACKUP:DELETE");
                  loadingState.value = true;
                  (await AsyncValue.guard(() async {
                    await ref.read(backupActionProvider).deleteBackup(
                        backupItem.backupId ?? 0,
                        backupItem.name ?? "",
                        msgMap);
                    await refresh();
                  }))
                      .showToastOnError(toast);
                  loadingState.value = false;
                },
                child: Text(context.l10n!.delete),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String formatFileSize(int fileSize) {
    if (fileSize < 1024) {
      return '$fileSize B';
    }
    double size = fileSize / 1024;
    if (size < 1024) {
      return '${size.toStringAsFixed(2)} KB';
    }
    size /= 1024;
    if (size < 1024) {
      return '${size.toStringAsFixed(2)} MB';
    }
    size /= 1024;
    if (size < 1024) {
      return '${size.toStringAsFixed(2)} GB';
    }
    size /= 1024;
    return '${size.toStringAsFixed(2)} TB';
  }

  String buildBackupTitle(BuildContext context, BackupItem item) {
    var prefix = context.l10n!.backupNamePrefixNormal;
    if (item.type == 1) {
      prefix = context.l10n!.backupNamePrefixAuto;
    }
    if (item.type == 2) {
      prefix = context.l10n!.backupNamePrefixSchedule;
    }
    return prefix;
  }
}
