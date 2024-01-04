// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../global_providers/preference_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../browse_center/presentation/source/controller/source_controller.dart';
import '../../../domain/backup/backup_model.dart';
import '../../browse/widgets/repo_setting/repo_url_tile.dart';
import '../controller/backup_controller.dart';

class ImportBackupDialog extends HookConsumerWidget {
  const ImportBackupDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupStatus = ref.watch(backupSocketProvider);
    useEffect(() {
      final status = backupStatus.valueOrNull;
      log("[Import] client status update to ${status?.state}, message: ${status?.message}");

      if (status?.state == BackupState.success.value) {
        Future(() {
          ref.read(markNeedAskRateProvider.notifier).update(true);
          if (status?.codes?.isNotEmpty == true) {
            final enabledLanguages = ref.watch(sourceLanguageFilterProvider);
            final result = {...?enabledLanguages, ...?status?.codes}.toList();
            log("[Import]before:$enabledLanguages, after:$result");
            ref.read(sourceLanguageFilterProvider.notifier).update(result);
          }
        });
      }
      return;
    }, [backupStatus]);

    final status = backupStatus.valueOrNull;
    if (status?.state == BackupState.success.value) {
      return AlertDialog(
        title: Text(context.l10n!.imported),
        content: Text(context.l10n!.importSuccessTip),
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
    }
    if (status?.state == BackupState.fail.value) {
      return AlertDialog(
        title: Text(backupStatus.valueOrNull?.message ?? "Import failed"),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n!.ok),
            onPressed: () {
              context.pop();
            },
          ),
        ],
      );
    }
    return AlertDialog(
      title: const CenterCircularProgressIndicator(),
      content: Text(backupStatus.valueOrNull?.message ?? "Importing..."),
    );
  }
}
