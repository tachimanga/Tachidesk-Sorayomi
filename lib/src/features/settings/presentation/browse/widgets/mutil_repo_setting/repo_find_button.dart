// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/urls.dart';
import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/launch_url_in_web.dart';
import '../../../../../../utils/misc/toast/toast.dart';

class RepoFindButton extends HookConsumerWidget {
  const RepoFindButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    final toast = ref.read(toastProvider(context));
    final userDefaults = ref.watch(sharedPreferencesProvider);
    if (magic.c0 == false) {
      return const SizedBox.shrink();
    }
    return TextButton.icon(
      onPressed: () {
        launchUrlInSafari(
          context,
          userDefaults.getString("config.repoFindUrl") ??
              AppUrls.findRepositories.url,
          toast,
        );
        pipe.invokeMethod("LogEvent", "REPO:ADD_BTN_TAP_FIND");
      },
      icon: const Icon(Icons.search_rounded),
      label: Text(context.l10n!.find_repository),
    );
  }
}
