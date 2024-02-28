// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../controller/security_controller.dart';

class LockSettingTile extends ConsumerWidget {
  const LockSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final toast = ref.read(toastProvider(context));

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final lockTypePref = ref.watch(lockTypePrefProvider) ?? LockTypeEnum.off;

    return ListTile(
      title: TextPremium(
        text: context.l10n!.lock_with_biometrics,
      ),
      subtitle: Text(lockTypePref.toLocale(context)),
      leading: const Icon(Icons.fingerprint_rounded),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<LockTypeEnum>(
          title: context.l10n!.lock_with_biometrics,
          optionList: LockTypeEnum.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: lockTypePref,
          onChange: (enumValue) async {
            pipe.invokeMethod("LogEvent", "LOCK:TYPE:${enumValue.name}");
            var setup = true;
            if (!purchaseGate && !testflightFlag) {
            } else if (enumValue == LockTypeEnum.biometrics) {
              setup = await setupBiometrics(context, toast);
            } else if (enumValue == LockTypeEnum.passcode) {
              setup = await setupPasscode(context, ref, pipe);
            }
            if (setup) {
              pipe.invokeMethod("LogEvent", "LOCK:SETUP:${enumValue.name}");
              ref.read(lockTypePrefProvider.notifier).update(enumValue);
              if (context.mounted) context.pop();
            }
          },
        ),
      ),
    );
  }

  Future<bool> setupBiometrics(BuildContext context, Toast toast) async {
    try {
      final errMsg = context.l10n!.lock_biometrics_unavailable;
      final unlockTitle = context.l10n!.unlock_title;
      final auth = LocalAuthentication();
      final availableBiometrics = await auth.getAvailableBiometrics();
      log("availableBiometrics $availableBiometrics");
      if (availableBiometrics.isEmpty) {
        toast.showError(errMsg);
        return false;
      }
      final bool didAuthenticate =
          await auth.authenticate(localizedReason: unlockTitle);
      log("didAuthenticate $didAuthenticate");
      if (!didAuthenticate) {
        toast.showError(errMsg);
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      toast.showError("${e.message}");
      return false;
    }
  }

  Future<bool> setupPasscode(
      BuildContext context, WidgetRef ref, MethodChannel pipe) async {
    final code = await pipe.invokeMethod("SECURITY:SET:PASSCODE");
    if (context.mounted && code is String && code.isNotBlank) {
      ref.read(lockPasscodePrefProvider.notifier).update(code);
      return true;
    }
    return false;
  }
}
