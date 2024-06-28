// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/language_list.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/radio_list_popup.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../lab/controller/pip_controller.dart';
import 'widgets/default_tab_tile/default_tab_tile.dart';

class GeneralScreen extends ConsumerWidget {
  const GeneralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final betaLocales = ['ja','ko','ml'];
    final testflightFlag = ref.watch(testflightFlagProvider);
    final locales = testflightFlag ||
            betaLocales.contains(context.currentLocale.languageCode)
        ? AppLocalizations.supportedLocales
        : AppLocalizations.supportedLocales
            .where((e) => !betaLocales.contains(e.languageCode))
            .toList();
    final showLabs = ref.watch(pipBuildFlagProvider) == true;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.general)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(context.l10n!.appLanguage),
            subtitle: Text(getLanguageNameFormLocale(context.currentLocale)),
            onTap: () => showDialog(
              context: context,
              builder: (context) => RadioListPopup<Locale>(
                title: context.l10n!.appLanguage,
                optionList: locales,
                value: context.currentLocale,
                onChange: (locale) {
                  ref.read(l10nProvider.notifier).update(locale);
                  context.pop();
                },
                optionDisplayName: getLanguageNameFormLocale,
                optionDisplaySubName: getLanguageEnNameFormLocale,
              ),
            ),
          ),
          const DefaultTabTile(),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: Text(context.l10n!.advanced),
            subtitle: Text(context.l10n!.advancedSubtitle),
            onTap: () => context.push([
              Routes.settings,
              Routes.generalSettings,
              Routes.advancedSettings
            ].toPath),
          ),
          if (showLabs) ...[
            ListTile(
              leading: const Icon(Icons.science),
              title: Text(context.l10n!.labs),
              subtitle: Text(context.l10n!.labsSubtitle),
              onTap: () => context.push([
                Routes.settings,
                Routes.generalSettings,
                Routes.labsSettings
              ].toPath),
            ),
          ],
        ],
      ),
    );
  }
}
