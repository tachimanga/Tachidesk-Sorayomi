// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../controller/auto_backup_controller.dart';

class AutoBackupFrequencyTile extends ConsumerWidget {
  const AutoBackupFrequencyTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final frequency =
        ref.watch(autoBackupFrequencyProvider) ?? FrequencyEnum.off;
    return ListTile(
      leading: const Icon(Icons.schedule_rounded),
      title: TextPremium(
        text: context.l10n!.pref_backup_interval,
      ),
      subtitle: Text(frequency.toLocale(context)),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<FrequencyEnum>(
          title: context.l10n!.pref_backup_interval,
          optionList: FrequencyEnum.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: frequency,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "BACKUP:AUTO:${enumValue.name}");
            ref.read(autoBackupFrequencyProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
