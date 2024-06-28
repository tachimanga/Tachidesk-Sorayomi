

import 'package:flutter/material.dart';
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