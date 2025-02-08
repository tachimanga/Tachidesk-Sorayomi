// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_constants.dart';
import '../../../routes/router_config.dart';
import '../../../utils/event_util.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/text_premium.dart';

class SyncSettingTile extends HookConsumerWidget {
  const SyncSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: TextPremium(text: context.l10n!.sync),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        logEvent3("SYNC:SETTING:TILE");
        context.push([Routes.settings, Routes.syncSettings].toPath);
      },
    );
  }
}