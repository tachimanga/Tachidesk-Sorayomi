// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../utils/purchase.dart';
import '../../../../../../widgets/text_premium.dart';
import '../../../../../custom/inapp/purchase_providers.dart';
import '../../../share/controller/share_controller.dart';


class WatermarkSwitchTile extends ConsumerWidget {
  const WatermarkSwitchTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final freeTrialFlag = ref.watch(freeTrialFlagProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.branding_watermark_outlined),
      title: TextPremium(text: context.l10n!.imageSaveWatermarkSwitch),
      onChanged: (value) async {
        pipe.invokeMethod("LogEvent", "READER:WATERMARK:$value");
        if (value == false) {
          final purchase = await checkPurchase(
              purchaseGate,
              testflightFlag,
              freeTrialFlag,
              context,
              toast);
          if (!purchase) {
            pipe.invokeMethod("LogEvent", "READER:WATERMARK:GATE");
            return;
          }
        }
        ref.read(watermarkSwitchProvider.notifier).update(value);
      },
      value: ref.watch(watermarkSwitchProvider).ifNull(),
    );
  }
}
