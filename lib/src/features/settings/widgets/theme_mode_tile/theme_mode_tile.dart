// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/app_constants.dart';
import '../../../../constants/db_keys.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../widgets/radio_list_popup.dart';

part 'theme_mode_tile.g.dart';

@riverpod
class ThemeModeKey extends _$ThemeModeKey
    with SharedPreferenceEnumClientMixin<ThemeMode> {
  @override
  ThemeMode? build() {
    return initialize(
      ref,
      initial: DBKeys.themeMode.initial,
      key: DBKeys.themeMode.name,
      enumList: ThemeMode.values,
    );
  }
}

extension ThemeModeExtension on ThemeMode {
  String toLocale(BuildContext context) {
    switch (this) {
      case ThemeMode.system:
        return context.l10n!.themeModeSystem;
      case ThemeMode.light:
        return context.l10n!.themeModeLight;
      case ThemeMode.dark:
        return context.l10n!.themeModeDark;
    }
  }
}

class AppThemeTile extends ConsumerWidget {
  const AppThemeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeKeyProvider);
    return ListTile(
      leading: Icon(
        context.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      ),
      subtitle: themeMode != null ? Text(themeMode.toLocale(context)) : null,
      title: Text(context.l10n!.appTheme),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ThemeMode>(
          title: context.l10n!.appTheme,
          optionList: ThemeMode.values,
          value: themeMode ?? ThemeMode.system,
          optionDisplayName: (value) => value.toLocale(context),
          onChange: (enumValue) async {
            ref.read(themeModeKeyProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
