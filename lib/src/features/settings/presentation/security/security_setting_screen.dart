// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/info_list_tile.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../custom/inapp/purchase_providers.dart';
import 'controller/security_controller.dart';
import 'widgets/incognito_mode_tile.dart';
import 'widgets/lock_interval_tile.dart';
import 'widgets/lock_setting_tile.dart';
import 'widgets/secure_screen_tile.dart';

class SecuritySettingScreen extends HookConsumerWidget {
  const SecuritySettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final lockTypePref = ref.watch(lockTypePrefProvider) ?? LockTypeEnum.off;
    final lockEnable = lockTypePref != LockTypeEnum.off;
    final premiumLockPref = !purchaseGate && !testflightFlag && lockEnable;

    final incognitoEnable = ref.watch(incognitoModePrefProvider) ?? false;
    final premiumIncognito = !purchaseGate && !testflightFlag && incognitoEnable;

    final secureScreenPref =
        ref.watch(secureScreenPrefProvider) ?? SecureScreenEnum.off;
    final secureEnable = secureScreenPref != SecureScreenEnum.off;
    final premiumSecurePref = !purchaseGate && !testflightFlag && secureEnable;

    return WillPopScope(
        onWillPop: premiumLockPref || premiumSecurePref || premiumIncognito
            ? () async {
                if (premiumLockPref) {
                  pipe.invokeMethod("LogEvent", "SECURITY:LOCK:RESET");
                  ref
                      .read(lockTypePrefProvider.notifier)
                      .update(LockTypeEnum.off);
                }
                if (premiumSecurePref) {
                  pipe.invokeMethod("LogEvent", "SECURITY:SCREEN:RESET");
                  ref
                      .read(secureScreenPrefProvider.notifier)
                      .update(SecureScreenEnum.off);
                }
                if (premiumIncognito) {
                  pipe.invokeMethod("LogEvent", "SECURITY:INCOGNITO:RESET");
                  ref
                      .read(incognitoModePrefProvider.notifier)
                      .update(false);
                }
                return true;
              }
            : null,
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n!.pref_category_security),
          ),
          body: ListView(
            children: [
              const LockSettingTile(),
              if (premiumLockPref) ...[
                const PremiumRequiredTile(),
              ],
              if (lockEnable) ...[
                const LockIntervalTile(),
              ],
              const Divider(),
              const IncognitoModeTile(),
              if (premiumIncognito) ...[
                const PremiumRequiredTile(),
              ],
              const Divider(),
              const SecureScreenTile(),
              if (premiumSecurePref) ...[
                const PremiumRequiredTile(),
              ],
              InfoListTile(infoText: context.l10n!.secure_screen_summary),
            ],
          ),
        ));
  }
}
