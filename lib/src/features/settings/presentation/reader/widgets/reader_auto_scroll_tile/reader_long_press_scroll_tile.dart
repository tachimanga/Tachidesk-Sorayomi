// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../widgets/premium_required_tile.dart';
import '../../../../../custom/inapp/purchase_providers.dart';
import 'reader_auto_scroll_controller.dart';

class ReaderLongPressScrollTile extends HookConsumerWidget {
  const ReaderLongPressScrollTile({
    super.key,
    this.globalReaderSetting,
  });

  final bool? globalReaderSetting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoScrolling = ref.watch(autoScrollingProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final premiumUser = purchaseGate || testflightFlag;

    final currInterval = ref.watch(autoSmoothScrollIntervalPrefProvider) ??
        DBKeys.autoSmoothScrollInterval.initial;
    final enablePref = ref.watch(longPressScrollPrefProvider) ??
        DBKeys.longPressScroll.initial;
    final enableFake = useState(false);
    final enable = premiumUser ? enablePref : enableFake.value;
    final label = context.l10n!.seconds_per_page(
      (autoScrollTransform(currInterval) / 1000).toStringAsFixed(1),
    );

    return ListTile(
      enabled: !autoScrolling,
      leading: const Icon(Icons.touch_app_rounded),
      title: Text(context.l10n!.hold_to_scroll),
      contentPadding: globalReaderSetting == true ? kSettingPadding : null,
      trailing: Switch(
        value: enable,
        onChanged: autoScrolling
            ? null
            : (value) {
                if (premiumUser) {
                  logEvent3("READER:HOLD:SCROLL:ENABLE:$value");
                  ref.read(longPressScrollPrefProvider.notifier).update(value);
                } else {
                  logEvent3("READER:HOLD:SCROLL:GATE:$value");
                  enableFake.value = value;
                }
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
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: autoScrolling ? context.theme.disabledColor : null,
                  ),
                ),
                Slider(
                  value: currInterval.toDouble(),
                  divisions: 90,
                  min: 1000,
                  max: 10 * 1000,
                  onChanged: autoScrolling
                      ? null
                      : (value) {
                          ref
                              .read(
                                  autoSmoothScrollIntervalPrefProvider.notifier)
                              .update(value.toInt());
                        },
                ),
                Text(
                  context.l10n!.hold_to_scroll_speed_up_tip,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.theme.disabledColor,
                  ),
                ),
                if (enableFake.value) ...[
                  const PremiumRequiredTile(),
                ],
              ],
            )
          : (globalReaderSetting == true
              ? Text(
                  context.l10n!.hold_to_scroll_tip,
                  style: context.textTheme.labelSmall
                      ?.copyWith(color: Colors.grey, fontSize: 12),
                )
              : Text(
                  context.l10n!.disable,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: autoScrolling ? context.theme.disabledColor : null,
                  ),
                )),
    );
  }
}
