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
import '../controller/security_controller.dart';

class LockIntervalTile extends ConsumerWidget {
  const LockIntervalTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final interval =
        ref.watch(lockIntervalPrefProvider) ?? LockIntervalEnum.always;
    return ListTile(
      leading: const Icon(Icons.schedule_rounded),
      title: Text(
        context.l10n!.lock_when_idle,
      ),
      subtitle: Text(interval.toLocale(context)),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<LockIntervalEnum>(
          title: context.l10n!.lock_when_idle,
          optionList: LockIntervalEnum.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: interval,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "LOCK:INTERVAL:${enumValue.name}");
            ref.read(lockIntervalPrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
