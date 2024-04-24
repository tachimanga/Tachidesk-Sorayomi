// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/enum.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../manga_book/presentation/reader/widgets/reader_navigation_layout/reader_navigation_layout.dart';
import 'widgets/reader_invert_tap_tile/reader_invert_tap_tile.dart';
import 'widgets/reader_navigation_layout_tile/reader_navigation_layout_tile.dart';
import 'widgets/reader_scroll_animation_tile/reader_scroll_animation_tile.dart';
import 'widgets/reader_show_tap_zone_tile/reader_show_tap_zone_tile.dart';

class ReaderTapZonesSettingsScreen extends ConsumerWidget {
  const ReaderTapZonesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(readerNavigationLayoutKeyProvider) ??
        ReaderNavigationLayout.disabled;

    return Scaffold(
        appBar: AppBar(title: Text(context.l10n!.readerNavigationLayout)),
        body: Column(
          children: [
            ListView(
              shrinkWrap: true,
              children: [
                const ReaderNavigationLayoutSettingTile(),
                if (layout != ReaderNavigationLayout.disabled) ...[
                  const ReaderScrollAnimationTile(),
                  if (layout != ReaderNavigationLayout.rightAndLeft) ...[
                    const ReaderInvertTapTile(),
                  ],
                  const ReaderShowTapZonesTile(),
                ],
                const Divider(),
              ],
            ),
            if (layout != ReaderNavigationLayout.disabled) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 20.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent),
                          ),
                          child: ReaderNavigationLayoutWidget(
                            onNext: () {},
                            onPrevious: () {},
                            navigationLayout: layout,
                            readerMode: ReaderMode.webtoon,
                            alwaysShow: true,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n!.readerNavigationLayout,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ));
  }
}
