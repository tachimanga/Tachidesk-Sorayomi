

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/db_keys.dart';
import '../constants/enum.dart';
import '../constants/language_list.dart';
import '../features/settings/presentation/server/widget/credential_popup/credentials_popup.dart';
import '../features/settings/widgets/server_url_tile/server_url_tile.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/log.dart';
import '../utils/mixin/shared_preferences_client_mixin.dart';
import '../utils/storage/dio/dio_client.dart';
import '../utils/storage/dio/network_module.dart';
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