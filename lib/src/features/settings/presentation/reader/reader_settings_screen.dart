// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/db_keys.dart';
import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';
import '../general/widgets/watermark_switch/watermark_switch.dart';
import 'widgets/reader_advanced_setting/reader_advanced_tile.dart';
import 'widgets/reader_mode_tile/reader_mode_tile.dart';
import 'widgets/reader_navigation_layout_tile/reader_navigation_layout_tile.dart';
import 'widgets/reader_padding_slider/reader_padding_slider.dart';
import 'widgets/reader_page_layout/reader_page_layout_tile.dart';

class ReaderSettingsScreen extends ConsumerWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final pageLayout = ref.watch(readerPageLayoutPrefProvider) ??
        DBKeys.readerPageLayout.initial;
    final premiumPageLayout = !purchaseGate &&
        !testflightFlag &&
        pageLayout != ReaderPageLayout.singlePage;

    return WillPopScope(
      onWillPop: premiumPageLayout
          ? () async {
              if (premiumPageLayout) {
                pipe.invokeMethod("LogEvent", "READER:LAYOUT:GLOBAL:RESET");
                ref
                    .read(readerPageLayoutPrefProvider.notifier)
                    .update(ReaderPageLayout.singlePage);
              }
              return true;
            }
          : null,
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n!.reader)),
        body: ListView(
          children: [
            const ReaderModeTile(),
            const ReaderPageLayoutTile(),
            if (premiumPageLayout) ...[
              const PremiumRequiredTile(),
            ],
            const ReaderNavigationLayoutTile(),
            const ReaderPaddingSlider(),
            const WatermarkSwitchTile(),
            const ReaderAdvancedTile(),
          ],
        ),
      ),
    );
  }
}
