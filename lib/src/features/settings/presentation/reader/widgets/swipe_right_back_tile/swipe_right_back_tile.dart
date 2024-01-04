// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/radio_list_popup.dart';

part 'swipe_right_back_tile.g.dart';

@riverpod
class SwipeRightBackPref extends _$SwipeRightBackPref
    with SharedPreferenceEnumClientMixin<SwipeRightToGoBackMode> {
  @override
  SwipeRightToGoBackMode? build() => initialize(
        ref,
        initial: DBKeys.swipeRightToGoBackMode.initial,
        key: DBKeys.swipeRightToGoBackMode.name,
        enumList: SwipeRightToGoBackMode.values,
      );
}

class SwipeRightBackTile extends ConsumerWidget {
  const SwipeRightBackTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final swipeRightMode =
        ref.watch(swipeRightBackPrefProvider) ?? SwipeRightToGoBackMode.always;
    return ListTile(
      leading: const Icon(Icons.swipe_rounded),
      subtitle: Text(swipeRightMode.toLocale(context)),
      title: Text(context.l10n!.swipeRightToGoBack),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<SwipeRightToGoBackMode>(
          title: context.l10n!.swipeRightToGoBack,
          optionList: SwipeRightToGoBackMode.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: swipeRightMode,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "READER:SWIPE_BACK:${enumValue.name}");
            ref.read(swipeRightBackPrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
