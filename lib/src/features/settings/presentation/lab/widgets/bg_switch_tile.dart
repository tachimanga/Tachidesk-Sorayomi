// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../controller/pip_controller.dart';

class BgSwitchTile extends HookConsumerWidget {
  const BgSwitchTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.download_for_offline_outlined),
      title: Text("Background download and update"),
      onChanged: (value) {
        logEvent3("PIP:SWITCH:$value");
        ref.read(bgEnablePrefProvider.notifier).update(value);
      },
      value: ref.watch(bgEnablePrefProvider).ifNull(),
    );
  }
}