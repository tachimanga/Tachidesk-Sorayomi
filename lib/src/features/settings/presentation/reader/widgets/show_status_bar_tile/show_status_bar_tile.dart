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

part 'show_status_bar_tile.g.dart';

@riverpod
class ShowStatusBarMode extends _$ShowStatusBarMode
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.showStatusBar.name,
    initial: DBKeys.showStatusBar.initial,
  );
}

class ShowStatusBarTile extends HookConsumerWidget {
  const ShowStatusBarTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.signal_cellular_alt_rounded),
      title: Text(context.l10n!.showStatusBar),
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "READER:STATUS_BAR:$value");
        ref.read(showStatusBarModeProvider.notifier).update(value);
      },
      value: ref.watch(showStatusBarModeProvider).ifNull(),
    );
  }
}
