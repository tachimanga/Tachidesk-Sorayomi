// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../icons/icomoon_icons.dart';
import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../widgets/text_premium.dart';

class ReaderApplePencilSettingTile extends ConsumerWidget {
  const ReaderApplePencilSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icomoon.pencilOutline),
      title: TextPremium(text: context.l10n!.apple_pencil_integration),
      subtitle: Text(context.l10n!.apple_pencil_integration_description),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => context.push([
        Routes.settings,
        Routes.readerSettings,
        Routes.readerApplePencilSettings
      ].toPath),
    );
  }
}
