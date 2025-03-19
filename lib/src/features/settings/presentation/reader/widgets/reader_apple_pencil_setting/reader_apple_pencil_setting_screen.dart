// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../widgets/info_list_tile.dart';
import '../../../../../../widgets/radio_list_popup.dart';
import '../reader_classic_start_button_tile/reader_classic_start_button_tile.dart';
import '../reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../reader_keep_screen_on/reader_keep_screen_on_tile.dart';
import '../reader_long_press_tile/reader_long_press_tile.dart';
import '../reader_pinch_to_zoom_tile/reader_pinch_to_zoom_tile.dart';
import '../show_status_bar_tile/show_status_bar_tile.dart';
import '../swipe_right_back_tile/swipe_right_back_tile.dart';
import 'reader_apple_pencil_controller.dart';

class ReaderApplePencilSettingScreen extends ConsumerWidget {
  const ReaderApplePencilSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.apple_pencil_integration),
      ),
      body: ListView(
        children:[
          ApplePencilDoubleTapTile(),
          ApplePencilSqueezeTile(),
          InfoListTile(infoText: context.l10n!.requires_apple_pencil_pro),
        ],
      ),
    );
  }
}

class ApplePencilDoubleTapTile extends ConsumerWidget {
  const ApplePencilDoubleTapTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(applePencilDoubleTabPrefProvider) ??
        ApplePencilActon.previousPage;
    return ListTile(
      leading: const Icon(Icons.keyboard_double_arrow_down),
      subtitle: Text(action.toLocale(context)),
      title: Text(context.l10n!.apple_pencil_double_tap),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ApplePencilActon>(
          title: context.l10n!.apple_pencil_double_tap,
          optionList: ApplePencilActon.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: action,
          onChange: (enumValue) async {
            logEvent3("READER:APPLE:PENCIL:DOUBLE:${enumValue.name}");
            ref
                .read(applePencilDoubleTabPrefProvider.notifier)
                .update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}

class ApplePencilSqueezeTile extends ConsumerWidget {
  const ApplePencilSqueezeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action =
        ref.watch(applePencilSqueezePrefProvider) ?? ApplePencilActon.nextPage;
    return ListTile(
      leading: const Icon(Icons.unfold_less),
      subtitle: Text(action.toLocale(context)),
      title: Text(context.l10n!.apple_pencil_squeeze),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ApplePencilActon>(
          title: context.l10n!.apple_pencil_squeeze,
          optionList: ApplePencilActon.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: action,
          onChange: (enumValue) async {
            logEvent3("READER:APPLE:PENCIL:SQUEEZE:${enumValue.name}");
            ref.read(applePencilSqueezePrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
