// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/urls.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';

class MigrateHelpButton extends HookConsumerWidget {
  const MigrateHelpButton({
    super.key,
    required this.icon,
  });

  final bool icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final userDefaults = ref.watch(sharedPreferencesProvider);

    final url = userDefaults.getString("config.migrateHelpUrl") ??
        AppUrls.migrateHelp.url;

    void onPressed() {
      launchUrlInWeb(context, url, toast);
    }

    if (icon) {
      return IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.help),
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.help_rounded),
      label: Text(context.l10n!.help),
    );
  }
}
