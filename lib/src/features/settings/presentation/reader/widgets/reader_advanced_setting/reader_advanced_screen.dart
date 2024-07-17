// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../reader_classic_start_button_tile/reader_classic_start_button_tile.dart';
import '../reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../reader_long_press_tile/reader_long_press_tile.dart';
import '../reader_pinch_to_zoom_tile/reader_pinch_to_zoom_tile.dart';
import '../show_status_bar_tile/show_status_bar_tile.dart';
import '../swipe_right_back_tile/swipe_right_back_tile.dart';

class ReaderAdvancedScreen extends ConsumerWidget {
  const ReaderAdvancedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.advanced),
        actions: [
          TextButton(
            onPressed: () => _resetSettings(ref),
            child: Text(context.l10n!.reset),
          ),
        ],
      ),
      body: ListView(
        children: const [
          SwipeRightBackTile(),
          ReaderDoubleTapZoomInTile(),
          ReaderPinchToZoomTile(),
          ReaderLongPressActionMenuTile(),
          ShowStatusBarTile(),
          ReaderClassicStartButtonTile(),
        ],
      ),
    );
  }

  void _resetSettings(WidgetRef ref) {
    ref
        .read(swipeRightBackPrefProvider.notifier)
        .update(DBKeys.swipeRightToGoBackMode.initial);
    ref
        .read(readerDoubleTapZoomInProvider.notifier)
        .update(DBKeys.doubleTapZoomIn.initial);
    ref
        .read(readerPinchToZoomProvider.notifier)
        .update(DBKeys.pinchToZoom.initial);
    ref
        .read(readerLongPressActionMenuPrefProvider.notifier)
        .update(DBKeys.longPressActionMenu.initial);
    ref
        .read(showStatusBarModeProvider.notifier)
        .update(DBKeys.showStatusBar.initial);
    ref
        .read(readerClassicStartButtonProvider.notifier)
        .update(DBKeys.classicStartButton.initial);
  }
}
