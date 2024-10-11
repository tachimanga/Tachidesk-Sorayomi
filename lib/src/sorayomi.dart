// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'constants/navigation_bar_data.dart';
import 'features/about/presentation/about/widget/file_log_tile.dart';
import 'features/custom/inapp/purchase_providers.dart';
import 'features/manga_book/presentation/downloads/service/download_ticket_service.dart';
import 'features/settings/domain/repo/repo_model.dart';
import 'features/settings/presentation/appearance/controller/theme_controller.dart';
import 'features/settings/widgets/theme_mode_tile/theme_mode_tile.dart';
import 'global_providers/global_providers.dart';
import 'global_providers/preference_providers.dart';
import 'routes/router_config.dart';
import 'utils/auto_delete.dart';
import 'utils/event_util.dart';
import 'utils/extensions/custom_extensions.dart';
import 'utils/http_proxy.dart';
import 'utils/log.dart';
import 'utils/premium_reset.dart';
import 'widgets/scrollbar_behavior.dart';

class Sorayomi extends HookConsumerWidget {
  const Sorayomi({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('main app build');

    final routes = ref.watch(routerConfigProvider);
    final themeMode = ref.watch(themeModeKeyProvider);
    final appLocale = decideAppLocale(ref);
    final appThemeData = ref.watch(themeSchemeColorProvider);

    final pipe = ref.watch(getMagicPipeProvider);
    setupHandler(pipe, routes, ref);

    // services
    final purchaseListener = ref.watch(purchaseListenerProvider);
    ref.watch(downloadTicketServiceProvider);

    setupProxy(ref);

    setupLog(ref);

    useEffect(() {
      PremiumReset.instance.resetWhenStartup(ref);
      ref.read(autoDeleteProvider.notifier).triggerDelete();
      return;
    }, []);

    return MaterialApp.router(
      // showPerformanceOverlay: true,
      onGenerateTitle: (context) => context.l10n!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: appThemeData.light,
      darkTheme: appThemeData.dark,
      themeMode: themeMode ?? ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appLocale,
      routeInformationProvider: routes.routeInformationProvider,
      routeInformationParser: routes.routeInformationParser,
      routerDelegate: routes.routerDelegate,
      scrollBehavior: ScrollbarBehavior(),
    );
  }

  Locale? decideAppLocale(WidgetRef ref) {
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
    log("matchLocale $matchLocale");
    return matchLocale ?? const Locale('en');
  }

  void setupHandler(MethodChannel pipe, GoRouter goRouter, WidgetRef ref) {
    pipe.setMethodCallHandler((call) async {
      log("call: ${call.method}, arg: ${call.arguments}");
      if (call.method == 'UPDATE_MAGIC') {
        await ref.read(sharedPreferencesProvider).reload();
        log("reload sharedPreferences succ");
      }
      if (call.method == 'OPENURL') {
        String fullUrl = call.arguments;
        final uri = Uri.parse(fullUrl);
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
            log("repo name: $name, repo: $repo");
            goRouter.go(Routes.more);
            final param = UrlSchemeAddRepo(repoName: name, baseUrl: repo);
            goRouter.push([
              Routes.settings,
              Routes.browseSettings,
              Routes.editRepo
            ].toPath, extra: param);

            closeSafariViewControllerIfNeeded();
            pipe.invokeMethod("LogEvent2", <String, Object?>{
              'eventName': 'REPO:ADD:BY_MANGA',
              'parameters': <String, String?>{
                'url': repo,
              },
            });
          }
        }
        if (uri.host == 'add-repo') {
          final url = uri.queryParameters["url"];
          if (url != null) {
            log("add-repo url: $url");
            goRouter.go(Routes.more);
            final param = UrlSchemeAddRepo(metaUrl: url);
            goRouter.push([
              Routes.settings,
              Routes.browseSettings,
              Routes.editRepo
            ].toPath, extra: param);

            closeSafariViewControllerIfNeeded();
            pipe.invokeMethod("LogEvent2", <String, Object?>{
              'eventName': 'REPO:ADD:BY_YOMI',
              'parameters': <String, String?>{
                'url': url,
              },
            });
          }
        }
        if (uri.host == 'go') {
          final url = uri.queryParameters["url"];
          if (url != null) {
            log("go url: $url");
            goRouter.push(url);
            logEvent3('NOTICE:TAP:GO', {'url': url});
          }
        }
        // file:///private/var/mobile/Containers/Data/Application/8FDA166C-D754-4E18-9E07-E9B5B3C36AB5/Documents/Inbox/Tachimanga_backup_2024-06-15_18-37-52-181.tmb
        if (fullUrl.startsWith("file://")) {
          log("import file: $fullUrl");
          if (fullUrl.endsWith(".zip") || fullUrl.endsWith(".tmb")) {
            goRouter.go(Routes.more);
            goRouter.push([
              Routes.settings,
              Routes.backup,
            ].toPath, extra: Uri.decodeFull(fullUrl).substring(7));
            logEvent3("BACKUP:IMPORT:FILE");
          }
        }
      }
      return Future.value('OK');
    });
  }

  void closeSafariViewControllerIfNeeded() {
    closeInAppWebView();
  }

  void setupProxy(WidgetRef ref) {
    log("main setupProxy");
    final proxy = ref.read(systemProxyProvider);
    final useSystemProxy = ref.read(useSystemProxyProvider);
    configHttpClient(proxy, useSystemProxy);
  }

  void setupLog(WidgetRef ref) {
    if (ref.read(fileLogProvider) == true) {
      logToNativeEnabled = true;
    }
  }
}
