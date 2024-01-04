// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/text_premium.dart';
import '../controller/theme_controller.dart';

class PureBlackDarkModeTile extends HookConsumerWidget {
  const PureBlackDarkModeTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final value = ref.watch(themePureBlackProvider) == true;
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      title: TextPremium(text: context.l10n!.themePureBlackDarkMode),
      onChanged: (value) {
        pipe.invokeMethod("LogEvent", "APPEARANCE:BLACK:$value");
        ref.read(themePureBlackProvider.notifier).update(value);
      },
      value: value,
    );
  }
}