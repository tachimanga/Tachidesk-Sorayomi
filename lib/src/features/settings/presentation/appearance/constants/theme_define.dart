// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import '../../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../../utils/extensions/custom_extensions.dart';

class ThemeDefine {
  static const Map<String, FlexSchemeData> schemesMap = {
    'default': defaultScheme,
    //'tachiyomi': tachiyomi,
    'greenapple': greenapple,
    'lavender': lavender,
    'midnightdusk': midnightdusk,
    'strawberry': strawberry,
    'tako': tako,
    'tealturqoise': tealturqoise,
    'tidalwave': tidalwave,
    'yinyang': yinyang,
    'yotsuba': yotsuba,
    'material': FlexColor.material,
    'materialHc': FlexColor.materialHc,
    'blue': FlexColor.blue,
    'indigo': FlexColor.indigo,
    'hippieBlue': FlexColor.hippieBlue,
    'aquaBlue': FlexColor.aquaBlue,
    'brandBlue': FlexColor.brandBlue,
    'deepBlue': FlexColor.deepBlue,
    'sakura': FlexColor.sakura,
    'mandyRed': FlexColor.mandyRed,
    'red': FlexColor.red,
    'redWine': FlexColor.redWine,
    'purpleBrown': FlexColor.purpleBrown,
    'green': FlexColor.green,
    'money': FlexColor.money,
    'jungle': FlexColor.jungle,
    'greyLaw': FlexColor.greyLaw,
    'wasabi': FlexColor.wasabi,
    'gold': FlexColor.gold,
    'mango': FlexColor.mango,
    'amber': FlexColor.amber,
    'vesuviusBurn': FlexColor.vesuviusBurn,
    'deepPurple': FlexColor.deepPurple,
    'ebonyClay': FlexColor.ebonyClay,
    'barossa': FlexColor.barossa,
    'shark': FlexColor.shark,
    'bigStone': FlexColor.bigStone,
    'damask': FlexColor.damask,
    'bahamaBlue': FlexColor.bahamaBlue,
    'mallardGreen': FlexColor.mallardGreen,
    'espresso': FlexColor.espresso,
    'outerSpace': FlexColor.outerSpace,
    'blueWhale': FlexColor.blueWhale,
    'sanJuanBlue': FlexColor.sanJuanBlue,
    'rosewood': FlexColor.rosewood,
    'blumineBlue': FlexColor.blumineBlue,
    'flutterDash': FlexColor.flutterDash,
    'materialBaseline': FlexColor.materialBaseline,
    'verdunHemlock': FlexColor.verdunHemlock,
    'dellGenoa': FlexColor.dellGenoa,
    'redM3': FlexColor.redM3,
    'pinkM3': FlexColor.pinkM3,
    'purpleM3': FlexColor.purpleM3,
    'indigoM3': FlexColor.indigoM3,
    'blueM3': FlexColor.blueM3,
    'cyanM3': FlexColor.cyanM3,
    'tealM3': FlexColor.tealM3,
    'greenM3': FlexColor.greenM3,
    'limeM3': FlexColor.limeM3,
    'yellowM3': FlexColor.yellowM3,
    'orangeM3': FlexColor.orangeM3,
    'deepOrangeM3': FlexColor.deepOrangeM3,
  };

  static String toLocale(String key, BuildContext context) {
    switch (key) {
      case "default":
        return context.l10n!.theme_default;
      case "monet":
        return context.l10n!.theme_monet;
      case "greenapple":
        return context.l10n!.theme_greenapple;
      case "lavender":
        return context.l10n!.theme_lavender;
      case "midnightdusk":
        return context.l10n!.theme_midnightdusk;
      case "strawberry":
        return context.l10n!.theme_strawberrydaiquiri;
      case "tako":
        return context.l10n!.theme_tako;
      case "tealturqoise":
        return context.l10n!.theme_tealturquoise;
      case "yinyang":
        return context.l10n!.theme_yinyang;
      case "yotsuba":
        return context.l10n!.theme_yotsuba;
      case "tidalwave":
        return context.l10n!.theme_tidalwave;
    }
    return key;
  }

  static const Color defaultLightTertiary = Color(0xFF006E1B);
  static const Color defaultDarkTertiary = Color(0xFF7ADC77);
  static const String defaultSchemeKey = "default";
  static const FlexSchemeData defaultScheme = FlexSchemeData(
    name: "default",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF335CA8),
      primaryContainer: Color(0xFFD8E2FF),
      secondary: Color(0xFF335CA8),
      secondaryContainer: Color(0xFFD8E2FF),
      tertiary: defaultLightTertiary,
      tertiaryContainer: Color(0xFF95F990),
      appBarColor: defaultLightTertiary,
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFAEC6FF),
      primaryContainer: Color(0xFF13448F),
      secondary: Color(0xFFAEC6FF),
      secondaryContainer: Color(0xFF13448F),
      tertiary: defaultDarkTertiary,
      tertiaryContainer: Color(0xFF005312),
      appBarColor: defaultDarkTertiary,
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData tachiyomi = FlexSchemeData(
    name: "tachiyomi",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF0057CE),
      primaryContainer: Color(0xFFD8E2FF),
      secondary: Color(0xFF0057CE),
      secondaryContainer: Color(0xFFD8E2FF),
      tertiary: Color(0xFF006E17),
      tertiaryContainer: Color(0xFF95F990),
      appBarColor: Color(0xFF006E17),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFAEC6FF),
      primaryContainer: Color(0xFF00419E),
      secondary: Color(0xFFAEC6FF),
      secondaryContainer: Color(0xFF00419E),
      tertiary: Color(0xFF7ADC77),
      tertiaryContainer: Color(0xFF00530D),
      appBarColor: Color(0xFF7ADC77),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData greenapple = FlexSchemeData(
    name: "greenapple",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF006D2F),
      primaryContainer: Color(0xFF96F8A9),
      secondary: Color(0xFF006D2F),
      secondaryContainer: Color(0xFF96F8A9),
      tertiary: Color(0xFFB91D22),
      tertiaryContainer: Color(0xFFFFDAD5),
      appBarColor: Color(0xFFB91D22),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF7ADB8F),
      primaryContainer: Color(0xFF005322),
      secondary: Color(0xFF7ADB8F),
      secondaryContainer: Color(0xFF005322),
      tertiary: Color(0xFFFFB3AA),
      tertiaryContainer: Color(0xFF93000D),
      appBarColor: Color(0xFFFFB3AA),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData lavender = FlexSchemeData(
    name: "lavender",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF7B46AF),
      primaryContainer: Color(0xFF7B46AF),
      secondary: Color(0xFF7B46AF),
      secondaryContainer: Color(0xFF7B46AF),
      tertiary: Color(0xFFEDE2FF),
      tertiaryContainer: Color(0xFFEDE2FF),
      appBarColor: Color(0xFFEDE2FF),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFA177FF),
      primaryContainer: Color(0xFFA177FF),
      secondary: Color(0xFFA177FF),
      secondaryContainer: Color(0xFFA177FF),
      tertiary: Color(0xFF5E25E1),
      tertiaryContainer: Color(0xFF111129),
      appBarColor: Color(0xFF5E25E1),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData midnightdusk = FlexSchemeData(
    name: "midnightdusk",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFFBB0054),
      primaryContainer: Color(0xFFFFD9E1),
      secondary: Color(0xFFBB0054),
      secondaryContainer: Color(0xFFFFD9E1),
      tertiary: Color(0xFF006638),
      tertiaryContainer: Color(0xFF00894b),
      appBarColor: Color(0xFF006638),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFF02475),
      primaryContainer: Color(0xFFBD1C5C),
      secondary: Color(0xFFF02475),
      secondaryContainer: Color(0xFFF02475),
      tertiary: Color(0xFF55971C),
      tertiaryContainer: Color(0xFF386412),
      appBarColor: Color(0xFF55971C),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData strawberry = FlexSchemeData(
    name: "strawberry",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFFB61E40),
      primaryContainer: Color(0xFFFFDADD),
      secondary: Color(0xFFB61E40),
      secondaryContainer: Color(0xFFFFDADD),
      tertiary: Color(0xFF775930),
      tertiaryContainer: Color(0xFFFFDDB1),
      appBarColor: Color(0xFF775930),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFFB2B9),
      primaryContainer: Color(0xFF91002A),
      secondary: Color(0xFFFFB2B9),
      secondaryContainer: Color(0xFF91002A),
      tertiary: Color(0xFFE8C08E),
      tertiaryContainer: Color(0xFF5D421B),
      appBarColor: Color(0xFFE8C08E),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData tako = FlexSchemeData(
    name: "tako",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF66577E),
      primaryContainer: Color(0xFF66577E),
      secondary: Color(0xFF66577E),
      secondaryContainer: Color(0xFF66577E),
      tertiary: Color(0xFFF3B375),
      tertiaryContainer: Color(0xFFFDD6B0),
      appBarColor: Color(0xFFF3B375),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFF3B375),
      primaryContainer: Color(0xFFF3B375),
      secondary: Color(0xFFF3B375),
      secondaryContainer: Color(0xFFF3B375),
      tertiary: Color(0xFF66577E),
      tertiaryContainer: Color(0xFF4E4065),
      appBarColor: Color(0xFF66577E),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData tealturqoise = FlexSchemeData(
    name: "tealturqoise",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF008080),
      primaryContainer: Color(0xFF008080),
      secondary: Color(0xFF008080),
      secondaryContainer: Color(0xFFBFDFDF),
      tertiary: Color(0xFFFF7F7F),
      tertiaryContainer: Color(0xFF2A1616),
      appBarColor: Color(0xFFFF7F7F),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF40E0D0),
      primaryContainer: Color(0xFF40E0D0),
      secondary: Color(0xFF40E0D0),
      secondaryContainer: Color(0xFF18544E),
      tertiary: Color(0xFFBF1F2F),
      tertiaryContainer: Color(0xFF200508),
      appBarColor: Color(0xFFBF1F2F),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData tidalwave = FlexSchemeData(
    name: "tidalwave",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF006780),
      primaryContainer: Color(0xFFB4D4DF),
      secondary: Color(0xFF006780),
      secondaryContainer: Color(0xFFb8eaff),
      tertiary: Color(0xFF92f7bc),
      tertiaryContainer: Color(0xFFc3fada),
      appBarColor: Color(0xFF92f7bc),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFF5ed4fc),
      primaryContainer: Color(0xFF004d61),
      secondary: Color(0xFF5ed4fc),
      secondaryContainer: Color(0xFF004d61),
      tertiary: Color(0xFF92f7bc),
      tertiaryContainer: Color(0xFFc3fada),
      appBarColor: Color(0xFF92f7bc),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData yinyang = FlexSchemeData(
    name: "yinyang",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFF000000),
      primaryContainer: Color(0xFF000000),
      secondary: Color(0xFF000000),
      secondaryContainer: Color(0xFFDDDDDD),
      tertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFD8E2FF),
      appBarColor: Color(0xFFFFFFFF),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF717171),
      tertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFF00419E),
      appBarColor: Color(0xFF000000),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );

  static const FlexSchemeData yotsuba = FlexSchemeData(
    name: "yotsuba",
    description: "",
    light: FlexSchemeColor(
      primary: Color(0xFFAE3200),
      primaryContainer: Color(0xFFFFDBCF),
      secondary: Color(0xFFAE3200),
      secondaryContainer: Color(0xFFFFDBCF),
      tertiary: Color(0xFF6B5E2F),
      tertiaryContainer: Color(0xFFF5E2A7),
      appBarColor: Color(0xFF6B5E2F),
      error: FlexColor.materialLightError,
      swapOnMaterial3: true,
    ),
    dark: FlexSchemeColor(
      primary: Color(0xFFFFB59D),
      primaryContainer: Color(0xFF862200),
      secondary: Color(0xFFFFB59D),
      secondaryContainer: Color(0xFF862200),
      tertiary: Color(0xFFD7C68D),
      tertiaryContainer: Color(0xFF524619),
      appBarColor: Color(0xFFD7C68D),
      error: FlexColor.materialDarkError,
      swapOnMaterial3: true,
    ),
  );
}
