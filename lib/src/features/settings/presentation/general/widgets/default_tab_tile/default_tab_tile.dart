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

part 'default_tab_tile.g.dart';

@riverpod
class DefaultTabPref extends _$DefaultTabPref
    with SharedPreferenceEnumClientMixin<DefaultTabEnum> {
  @override
  DefaultTabEnum? build() => initialize(
        ref,
        initial: DBKeys.defaultTab.initial,
        key: DBKeys.defaultTab.name,
        enumList: DefaultTabEnum.values,
      );
}

class DefaultTabTile extends ConsumerWidget {
  const DefaultTabTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultTab = ref.watch(defaultTabPrefProvider) ?? DefaultTabEnum.auto;
    final pipe = ref.watch(getMagicPipeProvider);
    return ListTile(
      leading: const Icon(Icons.home_rounded),
      title: Text(context.l10n!.defaultTab),
      subtitle: Text(defaultTab.toLocale(context)),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<DefaultTabEnum>(
          title: context.l10n!.defaultTab,
          optionList: DefaultTabEnum.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: defaultTab,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "READER:DEFAULT_TAB:${enumValue.name}");
            ref.read(defaultTabPrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
