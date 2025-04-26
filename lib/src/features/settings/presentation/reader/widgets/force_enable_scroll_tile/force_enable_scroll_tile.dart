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

part 'force_enable_scroll_tile.g.dart';

@riverpod
class ForceEnableScrollPref extends _$ForceEnableScrollPref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.forceEnableScroll.name,
        initial: DBKeys.forceEnableScroll.initial,
      );
}

class ForceEnableScrollTile extends ConsumerWidget {
  const ForceEnableScrollTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.touch_app_sharp),
      title: Text("Enable forced page scrolling in paged mode."),
      subtitle: Text(
        "Please only turn on this switch when you encounter unresponsive issues in paged mode. Once the switch is turned on, it may cause conflicts between pinch gestures and scroll gestures.",
        style: context.textTheme.labelSmall
            ?.copyWith(color: Colors.grey, fontSize: 10),
      ),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        ref.read(forceEnableScrollPrefProvider.notifier).update(value);
      },
      value: ref.watch(forceEnableScrollPrefProvider).ifNull(),
    );
  }
}
