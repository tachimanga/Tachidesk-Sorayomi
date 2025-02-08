// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart' as logger;
import '../../../../../../utils/log.dart';
import '../../../../../../widgets/premium_required_tile.dart';
import '../../../../../custom/inapp/purchase_providers.dart';
import 'reader_auto_scoll_controller.dart';

class ReaderAutoScrollTile extends HookConsumerWidget {
  const ReaderAutoScrollTile({
    super.key,
    required this.intervalState,
  });

  final ValueNotifier<int?> intervalState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = useState(0);
    final globalInterval = ref.watch(autoScrollIntervalPrefProvider) ??
        DBKeys.scrollAnimation.initial;
    final enable = intervalState.value != null;
    final currInterval = intervalState.value ?? globalInterval;
    final label = context.l10n!.seconds_per_page(
      (currInterval / 1000).toStringAsFixed(1),
    );

    // premium gate
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final premiumAutoscroll = !purchaseGate && !testflightFlag && enable;
    if (premiumAutoscroll) {
      useEffect(() {
        return () {
          Future(() {
            logEvent3("READER:AUTO:SCROLL:RESET");
            intervalState.value = null;
          });
        };
      }, []);
    }

    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.access_time_rounded),
      title: Text(context.l10n!.auto_scroll),
      onChanged: (value) {
        logger.log("[AUTO] set enable to $value");
        if (value) {
          logEvent3("READER:AUTO:SCROLL:ENABLE");
        }
        intervalState.value = value ? globalInterval : null;
        signal.value = signal.value + 1;
      },
      value: enable,
      subtitle: enable
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyMedium,
                ),
                Slider(
                  label: label.toString(),
                  value: currInterval.toDouble(),
                  divisions: 18,
                  min: 1000,
                  max: 10 * 1000,
                  onChanged: (value) {
                    logger.log("[AUTO] set interval to $value");
                    intervalState.value = value.toInt();
                    ref
                        .read(autoScrollIntervalPrefProvider.notifier)
                        .update(value.toInt());
                    signal.value = signal.value + 1;
                  },
                ),
                if (premiumAutoscroll) ...[
                  const PremiumRequiredTile(),
                ],
              ],
            )
          : Text(
              context.l10n!.disable,
              style: context.textTheme.bodyMedium,
            ),
    );
  }
}
