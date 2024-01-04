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
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../controller/auto_backup_controller.dart';

class AutoBackupLimitTile extends ConsumerWidget {
  const AutoBackupLimitTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit =
        ref.watch(autoBackupLimitProvider) ?? DBKeys.autoBackupLimit.initial;
    return ListTile(
      leading: const Icon(Icons.arrow_upward_rounded),
      title: Text(context.l10n!.pref_backup_slots),
      subtitle: Text("$limit"),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<int>(
          title: context.l10n!.pref_backup_slots,
          optionList: const [2, 3, 4, 5],
          optionDisplayName: (value) => "$value",
          value: limit,
          onChange: (value) async {
            ref.read(autoBackupLimitProvider.notifier).update(value);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
