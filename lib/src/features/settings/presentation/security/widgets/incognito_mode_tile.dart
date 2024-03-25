// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/gen/assets.gen.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../controller/security_controller.dart';

class IncognitoModeTile extends HookConsumerWidget {
  const IncognitoModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final value = ref.watch(incognitoModePrefProvider) == true;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: ImageIcon(
        AssetImage(Assets.icons.incognito.path),
      ),
      title: TextPremium(text: context.l10n!.pref_incognito_mode),
      subtitle: Text(context.l10n!.pref_incognito_mode_summary),
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "INCOGNITO:SETTING:$value");
        ref.read(incognitoModePrefProvider.notifier).update(value);
        if (value && (purchaseGate || testflightFlag)) {
          ref.read(incognitoModeUsedPrefProvider.notifier).update(true);
        }
      },
      value: value,
    );
  }
}

class IncognitoModeShortTile extends HookConsumerWidget {
  const IncognitoModeShortTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final value = ref.watch(incognitoModePrefProvider) == true;

    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: ImageIcon(
        AssetImage(Assets.icons.incognito.path),
      ),
      title: Text(context.l10n!.pref_incognito_mode),
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "INCOGNITO:SHORT:$value");
        ref.read(incognitoModePrefProvider.notifier).update(value);
      },
      value: value,
    );
  }
}
