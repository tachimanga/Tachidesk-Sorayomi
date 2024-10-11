// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/app_sizes.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../../../widgets/radio_list_popup.dart';
import '../../../../../manga_book/presentation/reader/widgets/reader_navigation_layout/reader_navigation_layout.dart';
import '../reader_invert_tap_tile/reader_invert_tap_tile.dart';
import '../reader_scroll_animation_tile/reader_scroll_animation_tile.dart';

part 'reader_navigation_layout_tile.g.dart';

@riverpod
class ReaderNavigationLayoutKey extends _$ReaderNavigationLayoutKey
    with SharedPreferenceEnumClientMixin<ReaderNavigationLayout> {
  @override
  ReaderNavigationLayout? build() => initialize(
        ref,
        initial: DBKeys.readerNavigationLayout.initial,
        key: DBKeys.readerNavigationLayout.name,
        enumList: ReaderNavigationLayout.values,
      );
}

class ReaderNavigationLayoutTile extends ConsumerWidget {
  const ReaderNavigationLayoutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerNavigationLayout = ref.watch(readerNavigationLayoutKeyProvider);
    return ListTile(
      leading: const Icon(Icons.touch_app_rounded),
      subtitle: readerNavigationLayout != null
          ? Text(readerNavigationLayout.toLocale(context))
          : null,
      title: Text(context.l10n!.readerNavigationLayout),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => context.push([
        Routes.settings,
        Routes.readerSettings,
        Routes.readerTapZones
      ].toPath),
    );
  }
}

class ReaderNavigationLayoutSettingTile extends HookConsumerWidget {
  const ReaderNavigationLayoutSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerNavigationLayout = ref.watch(readerNavigationLayoutKeyProvider);
    useEffect(() {
      if (readerNavigationLayout == null ||
          readerNavigationLayout == ReaderNavigationLayout.disabled) {
        Future.microtask(
            () => showLayoutDialog(context, ref, readerNavigationLayout));
      }
      return;
    }, []);
    return ListTile(
      leading: const Icon(Icons.touch_app_rounded),
      subtitle: readerNavigationLayout != null
          ? Text(readerNavigationLayout.toLocale(context))
          : null,
      title: Text(context.l10n!.readerNavigationLayout),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showLayoutDialog(context, ref, readerNavigationLayout),
    );
  }

  void showLayoutDialog(
    BuildContext context,
    WidgetRef ref,
    ReaderNavigationLayout? readerNavigationLayout,
  ) {
    showDialog(
      context: context,
      builder: (context) => RadioListPopup<ReaderNavigationLayout>(
        title: context.l10n!.readerNavigationLayout,
        optionList: ReaderNavigationLayout.values.sublist(1),
        optionDisplayName: (value) => value.toLocale(context),
        value: readerNavigationLayout ?? ReaderNavigationLayout.disabled,
        onChange: (enumValue) async {
          ref
              .read(readerNavigationLayoutKeyProvider.notifier)
              .update(enumValue);
          if (context.mounted) context.pop();
        },
      ),
    );
  }
}
