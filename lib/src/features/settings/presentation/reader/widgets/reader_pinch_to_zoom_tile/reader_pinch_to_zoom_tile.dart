// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'reader_pinch_to_zoom_tile.g.dart';

@riverpod
class ReaderPinchToZoom extends _$ReaderPinchToZoom
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.pinchToZoom.name,
        initial: DBKeys.pinchToZoom.initial,
      );
}

class ReaderPinchToZoomTile extends HookConsumerWidget {
  const ReaderPinchToZoomTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.pinch_rounded),
      title: Text(context.l10n!.pinch_to_zoom),
      subtitle: Text(
        context.l10n!.pinch_to_zoom_tip,
        style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        logEvent3("READER:PINCH_TO_ZOOM:$value");
        ref.read(readerPinchToZoomProvider.notifier).update(value);
      },
      value: ref.watch(readerPinchToZoomProvider).ifNull(),
    );
  }
}
