// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import '../reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../reader_pinch_to_zoom_tile/reader_pinch_to_zoom_tile.dart';
import '../show_status_bar_tile/show_status_bar_tile.dart';
import '../swipe_right_back_tile/swipe_right_back_tile.dart';


class ReaderAdvancedScreen extends ConsumerWidget {
  const ReaderAdvancedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.advanced)),
      body: ListView(
        children: const [
          SwipeRightBackTile(),
          ReaderDoubleTapZoomInTile(),
          ReaderPinchToZoomTile(),
          ShowStatusBarTile(),
        ],
      ),
    );
  }
}
