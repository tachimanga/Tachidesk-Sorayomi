// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/gen/assets.gen.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/highlighted_container.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../settings/presentation/security/controller/security_controller.dart';

class IncognitoIconButton extends HookConsumerWidget {
  const IncognitoIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    final pipe = ref.watch(getMagicPipeProvider);
    final enable = ref.watch(incognitoModePrefProvider) == true;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    if (!enable && !purchaseGate && !testflightFlag) {
      return IconButton(
        onPressed: () =>
            context.push([Routes.settings, Routes.securitySettings].toPath),
        icon: ImageIcon(
          AssetImage(Assets.icons.incognito.path),
        ),
      );
    }

    return HighlightedContainer(
      highlighted: enable,
      child: IconButton(
        icon: ImageIcon(
          AssetImage(Assets.icons.incognito.path),
        ),
        onPressed: () {
          final value = !enable;
          pipe.invokeMethod("LogEvent", "INCOGNITO:HISTORY:$value");
          ref.read(incognitoModePrefProvider.notifier).update(value);
          toast.show(
            value
                ? context.l10n!.pref_incognito_mode_on
                : context.l10n!.pref_incognito_mode_off,
            gravity: ToastGravity.TOP,
          );
        },
      ),
    );
  }
}
