// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/text_premium.dart';
import '../controller/theme_controller.dart';

class FontFixFor185Tile extends ConsumerWidget {
  const FontFixFor185Tile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(fontFixFor185Provider) == true;
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text("Font fix for iOS18.5"),
      secondary: const Icon(Icons.font_download),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        logEvent3("APPEARANCE:FONT:FIX:$value");
        ref.read(fontFixFor185Provider.notifier).update(value);
      },
      value: value,
    );
  }
}