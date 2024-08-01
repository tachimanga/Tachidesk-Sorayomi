// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../controller/auto_backup_controller.dart';
import '../controller/backup_controller.dart';

class BackupToCloudTile extends ConsumerWidget {
  const BackupToCloudTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final backupToCloud =
        ref.watch(backupToCloudPrefProvider) ?? DBKeys.backupToCloud.initial;
    final canUseCloud = ref.watch(canUseCloudProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.cloud_circle_rounded),
      title: TextPremium(text: context.l10n!.backup_to_iCloud),
      subtitle: canUseCloud.valueOrNull != true
          ? Text(context.l10n!.iCloud_unavailable_tip)
          : Text(context.l10n!.backup_to_iCloud_tip),
      onChanged: canUseCloud.valueOrNull != true
          ? null
          : (value) async {
              pipe.invokeMethod("LogEvent", "BACKUP:CLOUD:$value");
              ref.read(backupToCloudPrefProvider.notifier).update(value);
              if (value) {
                pipe.invokeMethod("BACKUP:CLOUD:START");
              } else {
                pipe.invokeMethod("BACKUP:CLOUD:STOP");
              }
            },
      value: backupToCloud,
    );
  }
}

class FakeBackupToCloudTile extends ConsumerWidget {
  const FakeBackupToCloudTile({
    super.key,
    required this.backupToCloud,
  });

  final ValueNotifier<bool> backupToCloud;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.cloud_circle_rounded),
      title: TextPremium(text: context.l10n!.backup_to_iCloud),
      subtitle: Text(context.l10n!.backup_to_iCloud_tip),
      onChanged: (value) async {
        pipe.invokeMethod("LogEvent", "BACKUP:CLOUD:GATE");
        backupToCloud.value = value;
      },
      value: backupToCloud.value,
    );
  }
}
