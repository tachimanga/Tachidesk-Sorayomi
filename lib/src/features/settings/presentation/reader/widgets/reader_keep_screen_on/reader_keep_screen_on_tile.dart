// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'reader_keep_screen_on_tile.g.dart';

@riverpod
class ReaderKeepScreenOnPref extends _$ReaderKeepScreenOnPref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.keepScreenOnWhileReading.name,
        initial: DBKeys.keepScreenOnWhileReading.initial,
      );
}

class ReaderKeepScreenOnTile extends ConsumerWidget {
  const ReaderKeepScreenOnTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.light_mode),
      title: Text(context.l10n!.reader_keep_screen_on),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "READER:SCREEN_ON:$value");
        ref.read(readerKeepScreenOnPrefProvider.notifier).update(value);
      },
      value: ref.watch(readerKeepScreenOnPrefProvider).ifNull(),
    );
  }
}
