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
import 'reader_auto_scroll_controller.dart';

class ReaderAutoScrollTile extends HookConsumerWidget {
  const ReaderAutoScrollTile({
    super.key,
    required this.intervalState,
    required this.continuousMode,
    required this.autoScrollDemoMode,
  });

  final ValueNotifier<int?> intervalState;
  final bool? continuousMode;
  final ValueNotifier<bool> autoScrollDemoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = useState(0);
    final smoothInterval = ref.watch(autoSmoothScrollIntervalPrefProvider) ??
        DBKeys.autoSmoothScrollInterval.initial;
    final pagedInterval = ref.watch(autoScrollIntervalPrefProvider) ??
        DBKeys.autoScrollInterval.initial;
    final globalInterval =
        continuousMode == true ? smoothInterval : pagedInterval;
    final enable = intervalState.value != null;
    final currInterval = intervalState.value ?? globalInterval;
    final label = context.l10n!.seconds_per_page(
      (autoScrollTransform(currInterval) / 1000).toStringAsFixed(1),
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

    return ListTile(
      leading: const Icon(Icons.access_time_rounded),
      title: Text(context.l10n!.auto_scroll),
      trailing: Switch(
        value: enable,
        onChanged: (value) {
          logger.log("[AUTO] set enable to $value");
          if (value) {
            autoScrollDemoMode.value = true;
            logEvent3("READER:AUTO:SCROLL:ENABLE");
          }
          intervalState.value = value ? globalInterval : null;
          ref
              .read(autoScrollingProvider.notifier)
              .update(value);
          signal.value = signal.value + 1;
        },
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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
                  value: currInterval.toDouble(),
                  divisions: 90,
                  min: 1000,
                  max: 10 * 1000,
                  onChanged: (value) {
                    logger.log("[AUTO] set interval to $value");
                    autoScrollDemoMode.value = true;
                    intervalState.value = value.toInt();
                    if (continuousMode == true) {
                      ref
                          .read(autoSmoothScrollIntervalPrefProvider.notifier)
                          .update(value.toInt());
                    } else {
                      ref
                          .read(autoScrollIntervalPrefProvider.notifier)
                          .update(value.toInt());
                    }
                    ref
                        .read(autoScrollingProvider.notifier)
                        .update(true);
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
