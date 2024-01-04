// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/language_list.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../domain/language/language_model.dart';
import '../controller/extension_controller.dart';

class ExtensionLanguageFilterDialog extends ConsumerWidget {
  const ExtensionLanguageFilterDialog({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCodes = ref.watch(extensionFilterLangListProvider);
    final enabledLanguages = ref.watch(extensionLanguageFilterProvider);
    print("ExtensionLanguageFilterDialog languageCodes $languageCodes");
    print("ExtensionLanguageFilterDialog enabledLanguages $enabledLanguages");
    return AlertDialog(
      title: Text(context.l10n!.languages),
      content: SizedBox(
        height: context.heightScale(scale: .5),
        width: context.widthScale(scale: context.isSmallTablet ? .5 : .8),
        child: ListView.builder(
          itemCount: languageCodes.length,
          itemBuilder: (context, index) {
            final Language? language = languageMap[languageCodes[index]];
            final enabledLanguagesIndex =
                enabledLanguages?.indexOf(languageCodes[index]);
            return SwitchListTile(
              value: enabledLanguagesIndex != -1,
              onChanged: (value) {
                if (value) {
                  ref.read(extensionLanguageFilterProvider.notifier).update(
                        {...?enabledLanguages, languageCodes[index]}.toList(),
                      );
                } else {
                  if (!((enabledLanguagesIndex?.isNegative).ifNull(true))) {
                    ref.read(extensionLanguageFilterProvider.notifier).update(
                          [...?enabledLanguages]
                            ..removeAt(enabledLanguagesIndex!),
                        );
                  }
                }
              },
              title: Text(
                language?.localizedDisplayName(context) ?? languageCodes[index],
              ),
              subtitle: Text(language?.name ?? languageCodes[index]),
            );
          },
        ),
      ),
      actions: const [PopButton()],
    );
  }
}
