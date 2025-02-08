

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/language_list.dart';
import '../utils/log.dart';
import 'global_providers.dart';

part 'locale_providers.g.dart';


@riverpod
List<String> sysPreferLocales(ref) {
  List<String> preferLocales = [];
  final List<Locale> systemLocales = WidgetsBinding.instance.window.locales;
  log("systemLocales $systemLocales");
  if (systemLocales.isEmpty) {
    return preferLocales;
  }
  Locale systemLocale = systemLocales[0];
  if (systemLocale.languageCode == 'en') {
    return preferLocales;
  }
  for (final language in languageList) {
    final code = language['code'];
    if (code != null) {
      var languageCode = code;
      if (languageCode.contains('-')) {
        languageCode = languageCode.split('-').first;
      }
      if (systemLocale.languageCode == languageCode) {
        preferLocales.add(code);
      }
    }
  }
  log("preferLocales $preferLocales");
  return preferLocales;
}

@riverpod
Locale userPreferLocale(ref) {
  final userSettingLocale = ref.watch(l10nProvider);
  log('userSettingLocale $userSettingLocale');
  if (userSettingLocale != null) {
    return userSettingLocale;
  }

  // Returns the list of locales that user defined in the system settings.
  final List<Locale> systemLocales = WidgetsBinding.instance.window.locales;
  log("systemLocales $systemLocales");
  if (systemLocales.isEmpty) {
    return const Locale('en');
  } else {
    return systemLocales[0];
  }
}

@riverpod
Locale appLocale(ref) {
  final userSettingLocale = ref.watch(l10nProvider);
  log('[appLocale]userSettingLocale $userSettingLocale');
  if (userSettingLocale != null) {
    return userSettingLocale;
  }

  // Returns the list of locales that user defined in the system settings.
  final List<Locale> systemLocales = WidgetsBinding.instance.window.locales;
  log("[appLocale]systemLocales $systemLocales");
  if (systemLocales.isEmpty) {
    return const Locale('en');
  }
  Locale systemLocale = systemLocales[0];
  Locale? matchLocale;
  var maxScore = 0;
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == 'ja') {
      continue;
    }
    var score = 0;
    if (locale.languageCode == systemLocale.languageCode) {
      score += 10;
    }
    if (locale.countryCode != null && locale.countryCode == systemLocale.countryCode) {
      score += 1;
    }
    if (locale.scriptCode != null && locale.scriptCode == systemLocale.scriptCode) {
      score += 1;
    }
    if (score > maxScore) {
      maxScore = score;
      matchLocale = locale;
    }
  }
  log("[appLocale]matchLocale $matchLocale");
  return matchLocale ?? const Locale('en');
}