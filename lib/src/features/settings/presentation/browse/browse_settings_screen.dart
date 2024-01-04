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
import 'widgets/bypass_setting/bypass_switch.dart';
import 'widgets/repo_setting/repo_url_tile.dart';
import 'widgets/show_nsfw_switch/show_nsfw_switch.dart';

class BrowseSettingsScreen extends HookConsumerWidget {
  const BrowseSettingsScreen({
    super.key,
    this.repoName,
    this.repoUrl,
  });

  final String? repoName;
  final String? repoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var magic = ref.watch(getMagicProvider);
    showImportRepoIfNeeded(context, ref);
    bool alwaysShow = repoName != null && repoUrl != null;
    final repoUrlSetting = ref.watch(repoUrlProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final toast = ref.read(toastProvider(context));

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
          if (magic.a9 || alwaysShow || repoUrlSetting.isNotBlank) ...[
            const RepoUrlTile(),
            ListTile(
              subtitle: Text("To set external repositories, you need to agree to the following agreement:\n"
                  + "1. I understand that Tachimanga does not regulate external repositories in any way and that Tachimanga is not responsible for any damages or harm done to my device or my identity by using external extensions.\n"
                  + "2. I understand that Tachimanga is not affiliated with any external extensions.\n"
                  + "3. I agree to not use Tachimanga to view content that I do not have the rights for."),
              leading: const Icon(Icons.info_rounded),
              dense: true,
            ),
            if (magic.b4) ...[
              Center(
                  child: TextButton.icon(
                      onPressed: () => launchUrlInWeb(
                            context,
                            userDefaults.getString("config.helpUrl") ??
                                AppUrls.addRepo.url,
                            ref.read(toastProvider(context)),
                          ),
                      icon: const Icon(Icons.help_rounded),
                      label: Text(context.l10n!.help))),
            ],
            const Divider(),
          ],
          if (magic.a8 || alwaysShow) ...[
            const ShowNSFWTile(),
            ListTile(
              subtitle: Text(context.l10n!.nsfwInfo),
              leading: const Icon(Icons.info_rounded),
              dense: true,
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }

  void showImportRepoIfNeeded(BuildContext context, WidgetRef ref) {
    https: //stackoverflow.com/questions/74721839/how-do-you-show-a-dialog-snackbar-inside-a-useeffect-on-flutter
    if (repoUrl.isNotBlank && repoName.isNotBlank) {
      useEffect(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(context.l10n!.externalRepository),
              content: Text("${context.l10n!.addRepository} '$repoName'?\n$repoUrl"),
              actions: [
                const PopButton(),
                ElevatedButton(
                  onPressed: () {
                    ref.read(repoUrlProvider.notifier).update(repoUrl);
                    context.pop();
                  },
                  child: Text(context.l10n!.save),
                ),
              ],
            ),
          );
        });
      }, []);
    }
  }
}
