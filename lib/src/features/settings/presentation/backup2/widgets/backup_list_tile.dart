// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/date_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
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
    required this.onShare,
    required this.msgMap,
  });
  final BackupItem backupItem;
  final AsyncCallback refresh;
  final ValueNotifier<bool> loadingState;
  final VoidCallback onConfirm;
  final VoidCallback onShare;
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
                  formatLocalizedDateTime(
                      dateFormatPref, context, backupItem.createAt ?? 0),
                  style: context.textTheme.titleSmall,
                ),
                Text.rich(
                  TextSpan(
                    text:
                        "${backupItem.cloudBackup == true ? "${context.l10n!.iCloud_label} " : ""}"
                        "${buildBackupTitle(context, backupItem)} "
                        "${formatFileSize(backupItem.size ?? 0)}"
                        "${backupItem.remoteBackup == true ? " " : ""}",
                    style: context.textTheme.labelSmall
                        ?.copyWith(color: Colors.grey),
                    children: [
                      if (backupItem.remoteBackup == true) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            backupItem.downloaded == true
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_download_outlined,
                            size: context.textTheme.labelSmall?.fontSize,
                            color: Colors.grey,
                          ),
                        ),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
          PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.r16.radius,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: loadingState.value
                    ? null
                    : () async {
                        if (backupItem.remoteBackup == true &&
                            backupItem.downloaded != true) {
                          (await AsyncValue.guard(() async {
                            await ref
                                .read(backupActionProvider)
                                .downloadBackup(backupItem.name ?? "", msgMap);
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => BackupDownloadingDialog(
                                  name: backupItem.name ?? "",
                                  onComplete: onConfirm,
                                ),
                              );
                            }
                          }))
                              .showToastOnError(toast);
                          return;
                        }
                        onConfirm();
                      },
                child: Text(context.l10n!.restoreBackup),
              ),
              PopupMenuItem(
                onTap: () async {
                  if (backupItem.remoteBackup == true &&
                      backupItem.downloaded != true) {
                    (await AsyncValue.guard(() async {
                      await ref
                          .read(backupActionProvider)
                          .downloadBackup(backupItem.name ?? "", msgMap);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => BackupDownloadingDialog(
                            name: backupItem.name ?? "",
                            onComplete: onShare,
                          ),
                        );
                      }
                    }))
                        .showToastOnError(toast);
                    return;
                  }
                  onShare();
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

class BackupDownloadingDialog extends HookConsumerWidget {
  const BackupDownloadingDialog({
    super.key,
    required this.name,
    required this.onComplete,
  });
  final String name;
  final VoidCallback onComplete;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(backupListProvider);
    final backupItem =
        list.valueOrNull.firstWhereOrNull((element) => element.name == name);

    useEffect(() {
      final progress = backupItem?.downloadProgress ?? 0;
      log("[Cloud]download progress $progress");
      if (progress >= 100) {
        Future(() {
          context.pop();
          onComplete();
        });
      }
      return;
    }, [backupItem]);

    return AlertDialog(
      title: Text(context.l10n!.downloading_from_iCloud),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 5,
          ),
          CircularProgressIndicator(
            value: (backupItem?.downloadProgress ?? 0) > 0
                ? (backupItem?.downloadProgress ?? 0) / 100.0
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(context.l10n!.cancel),
          onPressed: () {
            context.pop();
          },
        ),
      ],
    );
  }
}
