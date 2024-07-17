// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_constants.dart';
import '../../../../constants/db_keys.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../../widgets/section_title.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../widgets/theme_mode_tile/theme_mode_tile.dart';
import 'constants/theme_define.dart';
import 'controller/app_icon_controller.dart';
import 'controller/theme_controller.dart';
import 'widgets/app_icon_select_tile.dart';
import 'widgets/blend_level_slider_tile.dart';
import 'widgets/data_format_select_tile.dart';
import 'widgets/grid_cover_min_width.dart';
import 'widgets/pure_black_dark_mode_tile.dart';
import 'widgets/theme_select_tile.dart';

class AppearanceScreen extends HookConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final themeKey = ref.watch(themeKeyProvider);
    final pureBlackMode = ref.watch(themePureBlackProvider);
    final appIconKey = ref.watch(appIconKeyPrefProvider);

    final premiumTheme = !purchaseGate &&
        !testflightFlag &&
        themeKey != ThemeDefine.defaultSchemeKey;
    final premiumBlackMode =
        !purchaseGate && !testflightFlag && pureBlackMode == true;
    final premiumIcon =
        !purchaseGate && !testflightFlag && appIconKey != kDefaultAppIconKey;

    final brightness = Theme.of(context).brightness;
    return WillPopScope(
      onWillPop: premiumTheme || premiumBlackMode || premiumIcon
          ? () async {
              if (premiumTheme) {
                pipe.invokeMethod("LogEvent", "APPEARANCE:THEME:RESET");
                ref
                    .read(themeKeyProvider.notifier)
                    .update(ThemeDefine.defaultSchemeKey);
              }
              if (premiumBlackMode) {
                pipe.invokeMethod("LogEvent", "APPEARANCE:BLACK:RESET");
                ref.read(themePureBlackProvider.notifier).update(false);
              }
              if (premiumIcon) {
                pipe.invokeMethod("LogEvent", "APPEARANCE:ICON:RESET");
                ref
                    .read(appIconKeyPrefProvider.notifier)
                    .update(kDefaultAppIconKey);
              }
              return true;
            }
          : null,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n!.appearance)),
        body: ListView(
          children: [
            SectionTitle(title: context.l10n!.themeSectionTitle),
            const AppThemeTile(),
            const ThemeSelector(),
            if (premiumTheme) ...[
              const PremiumRequiredTile(),
            ],
            if (brightness == Brightness.dark) ...[
              const PureBlackDarkModeTile(),
              if (premiumBlackMode) ...[
                const PremiumRequiredTile(),
              ],
            ],
            if (brightness == Brightness.light || pureBlackMode != true) ...[
              const BlendLevelSlider(),
            ],
            SectionTitle(title: context.l10n!.icon_section_title),
            const AppIconSelectTile(),
            if (premiumIcon) ...[
              const PremiumRequiredTile(),
            ],
            SectionTitle(title: context.l10n!.displaySectionTitle),
            const GridCoverMinWidth(),
            const DateFormatSelectTile(),
          ],
        ),
      ),
    );
  }
}
