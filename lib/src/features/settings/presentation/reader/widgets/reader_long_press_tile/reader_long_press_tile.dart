// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';

import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'reader_long_press_tile.g.dart';

@riverpod
class ReaderLongPressActionMenuPref extends _$ReaderLongPressActionMenuPref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.longPressActionMenu.name,
        initial: DBKeys.longPressActionMenu.initial,
      );
}

class ReaderLongPressActionMenuTile extends HookConsumerWidget {
  const ReaderLongPressActionMenuTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.touch_app_rounded),
      title: Text(context.l10n!.long_press_action_menu),
      onChanged: (value) {
        logEvent3("READER:LONG_PRESS:$value");
        ref.read(readerLongPressActionMenuPrefProvider.notifier).update(value);
      },
      value: ref.watch(readerLongPressActionMenuPrefProvider).ifNull(),
    );
  }
}
