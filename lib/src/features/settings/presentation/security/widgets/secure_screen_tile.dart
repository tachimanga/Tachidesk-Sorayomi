// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../controller/security_controller.dart';

class SecureScreenTile extends ConsumerWidget {
  const SecureScreenTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final pref = ref.watch(secureScreenPrefProvider) ?? SecureScreenEnum.off;
    return ListTile(
      leading: const Icon(Icons.visibility_off_rounded),
      title: TextPremium(
        text: context.l10n!.secure_screen,
      ),
      subtitle: Text(pref.toLocale(context)),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<SecureScreenEnum>(
          title: context.l10n!.secure_screen,
          optionList: const [SecureScreenEnum.off, SecureScreenEnum.always],
          optionDisplayName: (value) => value.toLocale(context),
          value: pref,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "LOCK:SCREEN:${enumValue.name}");
            ref.read(secureScreenPrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
