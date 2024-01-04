// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/enum.dart';
import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../../widgets/section_title.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../data/backup/backup_repository.dart';
import '../../domain/backup/backup_model.dart';
import 'controller/auto_backup_controller.dart';
import 'controller/backup_controller.dart';
import 'widgets/auto_backup_frequency_tile.dart';
import 'widgets/auto_backup_latest_tile.dart';
import 'widgets/auto_backup_limit_tile.dart';
import 'widgets/backup_list_tile.dart';
import 'widgets/import_backup_dialog.dart';

class BackupScreenV2 extends HookConsumerWidget {
  const BackupScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final magic = ref.watch(getMagicProvider);
    final pipe = ref.watch(getMagicPipeProvider);

    final backupList = ref.watch(backupListProvider);
    final loadingState = useState(false);

    final msgMap = {
      //BACKUP_DB_ERR, BACKUP_DB_NOT_VALID, BACKUP_CREATE_ZIP_FAIL
      "operationFailTip": context.l10n!.operationFailTip,
      // RESTORE_DB_NOT_VALID, BACKUP_FILE_NOT_EXIST, BACKUP_FILE_EXTRACT_FAIL, BACKUP_FILE_NOT_VALID
      "invalidBackup": context.l10n!.invalidBackup,
      //BACKUP_RESTORE_VERSION_NOT_SUPPORT
      "invalidBackupVersion": context.l10n!.invalidBackupVersion,
      //BACKUP_AUTO_BACKUP_FAIL
      "autoBackupFailTip": context.l10n!.autoBackupFailTip,
    };

    refresh() => ref.refresh(backupListProvider.future);

    useEffect(() {
      backupList.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [backupList]);

    useEffect(() {
      pipe.invokeMethod("SCREEN_ON", "1");
      return () {
        pipe.invokeMethod("SCREEN_ON", "0");
      };
    }, []);

    final autoBackupFrequency =
        ref.watch(autoBackupFrequencyProvider) ?? FrequencyEnum.off;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final autoBackupEnable = autoBackupFrequency != FrequencyEnum.off;
    final premiumAlertForAutoBackup =
        !purchaseGate && !testflightFlag && autoBackupEnable;

    final latestAutoBackupItem =
        backupList.valueOrNull?.firstWhereOrNull((e) => e.type == 2);

    return WillPopScope(
        onWillPop: premiumAlertForAutoBackup || loadingState.value == true
            ? () async {
                if (premiumAlertForAutoBackup) {
                  pipe.invokeMethod("LogEvent", "BACKUP:AUTO:RESET");
                  ref
                      .read(autoBackupFrequencyProvider.notifier)
                      .update(FrequencyEnum.off);
                }
                return loadingState.value == false;
              }
            : null,
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n!.backup),
            actions: magic.b7 == true
                ? [
                    IconButton(
                      onPressed: () => launchUrlInWeb(
                          context, AppUrls.backupHelp.url, toast),
                      icon: const Icon(Icons.help_rounded),
                    ),
                  ]
                : null,
          ),
          body: backupList.showUiWhenData(
            context,
            (data) {
              return Stack(
                children: [
                  if (loadingState.value) ...[
                    const CenterCircularProgressIndicator()
                  ],
                  RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView.builder(
                      itemCount: data.isBlank ? 1 : 2,
                      itemBuilder: (context, sectionIndex) {
                        if (sectionIndex == 0) {
                          return ListView(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ListTile(
                                title: Text(context.l10n!.createBackupTitle),
                                subtitle:
                                    Text(context.l10n!.createBackupDescription),
                                leading: const Icon(Icons.backup_rounded),
                                onTap: () async {
                                  if (loadingState.value) {
                                    return;
                                  }
                                  pipe.invokeMethod(
                                      "LogEvent", "BACKUP:CREATE");
                                  loadingState.value = true;
                                  (await AsyncValue.guard(() async {
                                    await ref
                                        .read(backupActionProvider)
                                        .createBackup(msgMap);
                                    await refresh();
                                    if (context.mounted) {
                                      showBackupCreatedDialog(context);
                                    }
                                  }))
                                      .showToastOnError(toast);
                                  loadingState.value = false;
                                },
                              ),
                              ListTile(
                                title: Text(context.l10n!.restoreBackupTitle),
                                subtitle: Text(
                                    context.l10n!.restoreBackupDescription),
                                leading: const Icon(Icons.restore_rounded),
                                onTap: () async {
                                  if (loadingState.value) {
                                    return;
                                  }
                                  pipe.invokeMethod(
                                      "LogEvent", "BACKUP:RESTORE:FILE");
                                  backupFilePicker(
                                      ref, context, loadingState, msgMap, pipe);
                                },
                              ),
                              if (magic.b7 == true)
                                ListTile(
                                  title: Text(context.l10n!.importBackupTitle),
                                  subtitle: Text(
                                      context.l10n!.importBackupDescription),
                                  leading: const Icon(
                                      Icons.add_circle_outline_rounded),
                                  onTap: () async {
                                    if (loadingState.value) {
                                      return;
                                    }
                                    pipe.invokeMethod(
                                        "LogEvent", "BACKUP:IMPORT");
                                    importFilePicker(ref, context, loadingState,
                                        msgMap, refresh);
                                  },
                                ),
                              SectionTitle(
                                  title: context.l10n!.autoBackupSectionTitle),
                              const AutoBackupFrequencyTile(),
                              if (autoBackupEnable) ...[
                                const AutoBackupLimitTile(),
                                if (latestAutoBackupItem != null) ...[
                                  AutoBackupLatestTile(
                                    backupItem: latestAutoBackupItem,
                                  ),
                                ],
                              ],
                              if (premiumAlertForAutoBackup) ...[
                                const PremiumRequiredTile(),
                              ],
                              const Divider(),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionTitle(
                                title: context.l10n!.backupsSectionTitle),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              itemCount: data?.length ?? 0,
                              itemBuilder: (context, index) => BackupListTile(
                                backupItem: data![index],
                                refresh: refresh,
                                loadingState: loadingState,
                                onConfirm: () {
                                  pipe.invokeMethod(
                                      "LogEvent", "BACKUP:RESTORE");
                                  showConfirmRestoreDialog(
                                      ref, context, loadingState, toast, msgMap,
                                      name: data[index].name);
                                },
                                msgMap: msgMap,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            refresh: refresh,
          ),
        ));
  }

  void showBackupCreatedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.backupCreated),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n!.ok),
              onPressed: () {
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

  void backupFilePicker(
      WidgetRef ref,
      BuildContext context,
      ValueNotifier<bool> loadingState,
      Map<String, String> msgMap,
      MethodChannel pipe) async {
    final toast = ref.read(toastProvider(context));
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if ((file?.files).isBlank) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    showConfirmRestoreDialog(ref, context, loadingState, toast, msgMap,
        path: file?.files.single.path);
  }

  void showConfirmRestoreDialog(WidgetRef ref, BuildContext context,
      ValueNotifier<bool> loadingState, Toast toast, Map<String, String> msgMap,
      {String? path, String? name}) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: Text(context.l10n!.restoreConfirmTitle),
              content: const ConfirmRestoreContent(backup: true),
              actions: <Widget>[
                TextButton(
                  child: Text(context.l10n!.cancel),
                  onPressed: () {
                    ctx.pop();
                  },
                ),
                TextButton(
                  child: Text(context.l10n!.confirm),
                  onPressed: () async {
                    ctx.pop();
                    loadingState.value = true;
                    (await AsyncValue.guard(() async {
                      await ref.read(backupActionProvider).restoreBackup(
                          name ?? "",
                          path ?? "",
                          ref.read(autoBackupProvider) == true,
                          msgMap);
                      if (context.mounted) {
                        showBackupRestoredDialog(ref, context);
                      }
                    }))
                        .showToastOnError(toast);
                    loadingState.value = false;
                  },
                ),
              ],
            ));
      },
    );
  }

  void showBackupRestoredDialog(WidgetRef ref, BuildContext context,
      {bool backup = true}) {
    showDialog(
      context: context,
      barrierDismissible: kDebugMode ? true : false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(backup ? context.l10n!.restored : context.l10n!.imported),
          content: Text(backup
              ? context.l10n!.restoreSuccessTip
              : context.l10n!.importSuccessTip),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n!.restartApp),
              onPressed: () {
                ref.read(getMagicPipeProvider).invokeMethod("BACKUP:RESTART");
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }

  void importFilePicker(
      WidgetRef ref,
      BuildContext context,
      ValueNotifier<bool> loadingState,
      Map<String, String> msgMap,
      AsyncCallback refresh) async {
    final toast = ref.read(toastProvider(context));
    final file = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if ((file?.files).isBlank) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    showConfirmImportDialog(
        ref, context, loadingState, toast, file?.files.single, msgMap, refresh);
  }

  void showConfirmImportDialog(
      WidgetRef ref,
      BuildContext context,
      ValueNotifier<bool> loadingState,
      Toast toast,
      PlatformFile? file,
      Map<String, String> msgMap,
      AsyncCallback refresh) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: Text(context.l10n!.importConfirmTitle),
              content: const ConfirmRestoreContent(backup: false),
              actions: <Widget>[
                TextButton(
                  child: Text(context.l10n!.cancel),
                  onPressed: () {
                    ctx.pop();
                  },
                ),
                TextButton(
                  child: Text(context.l10n!.confirm),
                  onPressed: () async {
                    ctx.pop();
                    loadingState.value = true;

                    (await AsyncValue.guard(() async {
                      if (ref.read(autoBackupProvider) == true) {
                        await ref
                            .read(backupActionProvider)
                            .createBackup(msgMap, type: 1);
                        await refresh();
                      }
                      if (!context.mounted) {
                        return;
                      }
                      await ref
                          .read(backupRepositoryProvider)
                          .restoreBackup(context, file);
                      if (!context.mounted) {
                        return;
                      }
                      showImportDialog(ref, context);
                    }))
                        .showDialogOnError(toast, context);
                    loadingState.value = false;
                  },
                ),
              ],
            ));
      },
    );
  }

  void showImportDialog(WidgetRef ref, BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: kDebugMode ? true : false,
      builder: (BuildContext context) {
        return const ImportBackupDialog();
      },
    );
  }
}

class ConfirmRestoreContent extends ConsumerWidget {
  const ConfirmRestoreContent({super.key, required this.backup});

  final bool backup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoBackup = ref.watch(autoBackupProvider);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(backup
            ? context.l10n!.restoreConfirmContent
            : context.l10n!.importConfirmContent),
        const SizedBox(
          height: 10,
        ),
        Row(
          children: [
            Checkbox(
              value: autoBackup == true,
              onChanged: (value) {
                ref.read(autoBackupProvider.notifier).update(value == true);
              },
            ),
            Expanded(
              child: Text(backup
                  ? context.l10n!.autoBackupTip
                  : context.l10n!.autoBackupTipForImport),
            ),
          ],
        ),
      ],
    );
  }
}

extension BackupAsyncValueExtensions<T> on AsyncValue<T> {
  void showDialogOnError(Toast toast, BuildContext context) {
    if (!isRefreshing) {
      whenOrNull(
        error: (error, stackTrace) {
          if (error.toString() ==
                  "java.lang.OutOfMemoryError: Java heap space" &&
              context.mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Import failed: Backup file is too large."),
                  content: const Text(
                      "When creating a backup of Tachiyomi, only backup Library, Categories, and Tracking, then retry."),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }
          toast.close();
          toast.showError(error.toString());
        },
      );
    }
  }
}
