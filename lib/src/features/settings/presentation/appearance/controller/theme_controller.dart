// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_themes/app_theme.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../constants/theme_define.dart';

part 'theme_controller.g.dart';


@riverpod
class ThemeKey extends _$ThemeKey with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
    ref,
    key: DBKeys.themeKey.name,
    initial: DBKeys.themeKey.initial,
  );
}

@riverpod
class ThemePureBlack extends _$ThemePureBlack with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.themePureBlackDarkMode.name,
    initial: DBKeys.themePureBlackDarkMode.initial,
  );
}

@riverpod
class ThemeBlendLevel extends _$ThemeBlendLevel
    with SharedPreferenceClientMixin<double> {
  @override
  double? build() => initialize(
    ref,
    key: DBKeys.themeBlendLevel.name,
    initial: DBKeys.themeBlendLevel.initial,
  );
}


@riverpod
class ThemeSchemeColor extends _$ThemeSchemeColor {
  @override
  AppThemeData build() {
    final key = ref.watch(themeKeyProvider);
    final blendLevel = ref.watch(themeBlendLevelProvider) ?? DBKeys.themeBlendLevel.initial;
    final pureBlackDarkMode = ref.watch(themePureBlackProvider) ?? DBKeys.themePureBlackDarkMode.initial;
    final scheme = ThemeDefine.schemesMap[key] ?? ThemeDefine.defaultScheme;
    ThemeData themeLight = FlexThemeData.light(
      colors: scheme.light,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: blendLevel.toInt(),
      appBarOpacity: 0.00,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        unselectedToggleIsColored: true,
        inputDecoratorIsFilled: false,
      ),
      useMaterial3ErrorColors: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
    ThemeData themeDark = FlexThemeData.dark(
      colors: scheme.dark,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: blendLevel.toInt(),
      appBarOpacity: 0.00,
      scaffoldBackground: pureBlackDarkMode ? Colors.black : null,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useTextTheme: true,
        useM2StyleDividerInM3: true,
        unselectedToggleIsColored: true,
        inputDecoratorIsFilled: false,
      ),
      useMaterial3ErrorColors: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    );
    return AppThemeData(themeLight, themeDark);
  }
}