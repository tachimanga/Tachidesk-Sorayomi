// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/db_keys.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';
import '../../../../widgets/slider_setting_tile/slider_setting_tile.dart';

part 'reader_padding_slider.g.dart';

@riverpod
class ReaderPaddingKey extends _$ReaderPaddingKey
    with SharedPreferenceClientMixin<double> {
  @override
  double? build() => initialize(
        ref,
        initial: DBKeys.readerPadding.initial,
        key: DBKeys.readerPadding.name,
      );
}

class ReaderPaddingSlider extends ConsumerWidget {
  const ReaderPaddingSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double readerPadding =
        ref.watch(readerPaddingKeyProvider) ?? DBKeys.readerPadding.initial;
    return SliderSettingTile(
      icon: Icons.width_wide_rounded,
      title: context.l10n!.readerPadding,
      value: readerPadding,
      labelGenerator: (val) => (val * 2.5).toStringAsFixed(2),
      onChanged: ref.read(readerPaddingKeyProvider.notifier).update,
      defaultValue: DBKeys.readerPadding.initial,
      min: 0,
      max: 0.4,
    );
  }
}

class AsyncReaderPaddingSlider extends HookConsumerWidget {
  const AsyncReaderPaddingSlider({
    super.key,
    required this.onChanged,
    required this.mangaId,
  });

  final ValueSetter<double> onChanged;
  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debounce = useRef<Timer?>(null);

    final readerPaddingProvider = readerPaddingWithMangaIdProvider(mangaId: mangaId);
    final readerPadding = ref.watch(readerPaddingProvider);

    final onDebounceChanged = useCallback<ValueSetter<double>>(
      (double paddingValue) async {
        ref.read(readerPaddingProvider.notifier).update(paddingValue);
        final finalDebounce = debounce.value;
        if ((finalDebounce?.isActive).ifNull()) {
          finalDebounce?.cancel();
        }
        debounce.value = Timer(
          kDebounceDuration,
          () => onChanged(paddingValue),
        );
        return;
      },
      [],
    );
    return SliderSettingTile(
      icon: Icons.width_wide_rounded,
      title: context.l10n!.readerPadding,
      value: readerPadding,
      labelGenerator: (val) => (val * 2.5).toStringAsFixed(2),
      onChanged: onDebounceChanged,
      defaultValue: DBKeys.readerPadding.initial,
      min: 0,
      max: 0.4,
    );
  }
}
