// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';
import '../../../../widgets/slider_setting_tile/slider_setting_tile.dart';

class MouseWheelSpeedSlider extends ConsumerWidget {
  const MouseWheelSpeedSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double speed =
        ref.watch(mouseWheelSpeedPrefProvider) ?? DBKeys.mouseWheelSpeed.initial;
    return SliderSettingTile(
      icon: Icons.mouse,
      title: context.l10n!.mouse_wheel_speed,
      value: speed.toDouble(),
      labelGenerator: (val) => val.toStringAsFixed(2),
      onChanged: (value) {
        ref.read(mouseWheelSpeedPrefProvider.notifier).update(value);
      },
      defaultValue: DBKeys.mouseWheelSpeed.initial,
      min: 0.5,
      max: 10,
    );
  }
}