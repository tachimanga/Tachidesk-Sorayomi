// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/pop_button.dart';
import '../../controller/edit_repo_controller.dart';
import 'widgets/bypass_setting/bypass_switch.dart';
import 'widgets/mutil_repo_setting/edit_repo_tile.dart';
import 'widgets/repo_setting/repo_url_tile.dart';
import 'widgets/show_nsfw_switch/show_nsfw_switch.dart';

class BrowseSettingsScreen extends HookConsumerWidget {
  const BrowseSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final toast = ref.read(toastProvider(context));
    final repoCount = ref.watch(repoCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.extensions),
        actions: magic.b7 == true
            ? [
                IconButton(
                  onPressed: () =>
                      launchUrlInWeb(context, AppUrls.extensionHelp.url, toast),
                  icon: const Icon(Icons.help_rounded),
                ),
              ]
            : null,
      ),
      body: ListView(
        children: [
          if (magic.a9 || repoCount > 0) ...[
            const EditRepoTile(),
            ListTile(
              subtitle: Text(
                context.l10n!.extension_usage_terms,
                style:
                    context.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              leading: const Icon(Icons.info_rounded),
              dense: true,
            ),
            const Divider(),
          ],
          if (magic.a8 && repoCount > 0) ...[
            const ShowNSFWTile(),
            ListTile(
              subtitle: Text(
                context.l10n!.nsfwInfo,
                style:
                    context.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              leading: const Icon(Icons.info_rounded),
              dense: true,
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
