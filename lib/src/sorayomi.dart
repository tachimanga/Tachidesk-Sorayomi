// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'constants/app_themes/color_schemas/default_theme.dart';
import 'constants/navigation_bar_data.dart';
import 'features/custom/inapp/purchase_providers.dart';
import 'features/settings/widgets/theme_mode_tile/theme_mode_tile.dart';
import 'global_providers/global_providers.dart';
import 'global_providers/preference_providers.dart';
import 'routes/router_config.dart';
import 'utils/extensions/custom_extensions.dart';
import 'utils/http_proxy.dart';
import 'utils/log.dart';

class Sorayomi extends ConsumerWidget {
  const Sorayomi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final routes = ref.watch(routerConfigProvider);
    final themeMode = ref.watch(themeModeKeyProvider);
    final appLocale = decideAppLocale(ref);

    final pipe = ref.watch(getMagicPipeProvider);
    setupHandler(pipe, routes, ref);

    setupProxy(ref);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: defaultTheme.light,
      darkTheme: defaultTheme.dark,
      themeMode: themeMode ?? ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLocale,
      routeInformationProvider: routes.routeInformationProvider,
      routeInformationParser: routes.routeInformationParser,
      routerDelegate: routes.routerDelegate,
    );
  }

  Locale? decideAppLocale(WidgetRef ref) {
    final userSettingLocale = ref.watch(l10nProvider);
    print('userSettingLocale $userSettingLocale');
    if (userSettingLocale != null) {
      return userSettingLocale;
    }

    // Returns the list of locales that user defined in the system settings.
    final List<Locale> systemLocales = WidgetsBinding.instance.window.locales;
    print("systemLocales $systemLocales");
    if (systemLocales.isEmpty) {
      return const Locale('en');
    }
    Locale systemLocale = systemLocales[0];
    Locale? matchLocale;
    var maxScore = 0;
    for (final locale in AppLocalizations.supportedLocales) {
      var score = 0;
      if (locale.languageCode == systemLocale.languageCode) {
        score += 10;
      }
      if (locale.countryCode == systemLocale.countryCode) {
        score += 1;
      }
      if (locale.scriptCode == systemLocale.scriptCode) {
        score += 1;
      }
      if (score > maxScore) {
        maxScore = score;
        matchLocale = locale;
      }
    }
    print("matchLocale $matchLocale");
    return matchLocale ?? const Locale('en');
  }

  void setupHandler(MethodChannel pipe, GoRouter goRouter, WidgetRef ref) {
    pipe.setMethodCallHandler((call) {
      log("call: ${call.method}, arg: ${call.arguments}");
      if (call.method == 'OPENURL') {
        final uri = Uri.parse(call.arguments);
        //final location = goRouter.location;
        //print("location: $location");
        if (uri.host == 'tab') {
          final index = uri.queryParameters["index"];
          if (index != null) {
            //print("index$index");
            int val = int.tryParse(index) ?? -1;
            if (val >= 0 && val < NavigationBarData.navList.length) {
                goRouter.go(NavigationBarData.navList[val].path);
            }
          }
        }
        if (uri.host == 'repo') {
          final name = uri.queryParameters["name"];
          final repo = uri.queryParameters["url"];
          if (name != null && repo != null) {
            log("name: $name, repo: $repo");
            goRouter.go(Routes.more);
            goRouter.push([Routes.settings, Routes.getExtensionSetting(name, repo)].toPath);
          }
        }
      }
      return Future.value('OK');
    });
  }

  void setupProxy(WidgetRef ref) {
    log("main setupProxy");
    final proxy = ref.read(systemProxyProvider);
    final useSystemProxy = ref.read(useSystemProxyProvider);
    configHttpClient(proxy, useSystemProxy);
  }
}
