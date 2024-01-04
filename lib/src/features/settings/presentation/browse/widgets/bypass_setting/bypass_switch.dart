// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'bypass_switch.g.dart';

@riverpod
class ByPassSwitch extends _$ByPassSwitch with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.disableBypass.name,
        initial: DBKeys.disableBypass.initial,
      );
}

class ByPassTile extends ConsumerWidget {
  const ByPassTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.block_rounded),
      title: Text(
        context.l10n!.byPassSwitch,
      ),
      onChanged: (value) => ref.read(byPassSwitchProvider.notifier).update(!value),
      value: !ref.watch(byPassSwitchProvider).ifNull(DBKeys.disableBypass.initial),
    );
  }
}
