// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'reader_double_tap_zoom_in_tile.g.dart';

@riverpod
class ReaderDoubleTapZoomIn extends _$ReaderDoubleTapZoomIn
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.doubleTapZoomIn.name,
    initial: DBKeys.doubleTapZoomIn.initial,
  );
}

class ReaderDoubleTapZoomInTile extends HookConsumerWidget {
  const ReaderDoubleTapZoomInTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.zoom_in_rounded),
      title: Text(context.l10n!.doubleTapZoomIn),
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "READER:ZOOM_IN:$value");
        ref.read(readerDoubleTapZoomInProvider.notifier).update(value);
      },
      value: ref.watch(readerDoubleTapZoomInProvider).ifNull(),
    );
  }
}
