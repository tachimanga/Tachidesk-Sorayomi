// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/gen/assets.gen.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import 'controllers/about_controller.dart';
import 'widget/clipboard_list_tile.dart';

class AboutScreenLite extends HookConsumerWidget {
  const AboutScreenLite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final toast = ref.watch(toastProvider(context));
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final translateUrl = userDefaults.getString("config.translateUrl");
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.about),
      ),
      body: ListView(
        children: [
          ImageIcon(
            AssetImage(Assets.icons.darkIcon.path),
            size: context.height * .1,
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n!.clientVersion),
            subtitle:
                Text("v${packageInfo.version}(${packageInfo.buildNumber})"),
            leading: const Icon(Icons.translate_rounded),
          ),
          ListTile(
            title: Text(context.l10n!.changelogs),
            leading: const Icon(Icons.history_rounded),
            onTap: () => launchUrlInWeb(
              context,
              userDefaults.getString("config.changelogs") ?? AppUrls.changelogs.url,
              ref.read(toastProvider(context)),
            ),
          ),
          ListTile(
            title: Text(context.l10n!.help),
            leading: const Icon(Icons.help_rounded),
            onTap: () => launchUrlInWeb(
              context,
              userDefaults.getString("config.faqUrl") ?? AppUrls.faqUrl.url,
              ref.read(toastProvider(context)),
            ),
          ),
          ListTile(
            title: Text(context.l10n!.contact_us),
            leading: const Icon(Icons.forum_rounded),
            onTap: () {
              pipe.invokeMethod("LogEvent", "TAP_CONTACT_US");
              pipe.invokeMethod("SEND_MAIL", <String, Object?>{
                'recipient': 'tachimangaapp+fb@gmail.com',
                'title': '',
                'content': "\n\n\nTachimanga version: ${packageInfo.version}(${packageInfo.buildNumber})",
              });
            },
          ),
          if (translateUrl?.isNotEmpty == true) ...[
            ListTile(
              title: Text(context.l10n!.help_translate),
              leading: const Icon(Icons.translate_rounded),
              onTap: () => launchUrlInWeb(
                context,
                translateUrl ?? "",
                ref.read(toastProvider(context)),
              ),
            ),
          ],
          const Divider(),
          ListTile(
              title: const Text("Credit"),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text:
                            'This app is based on the following awesome projects: '),
                    TextSpan(
                      text: 'Tachidesk-Server',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlInWeb(
                              context,
                              "https://github.com/Suwayomi/Tachidesk-Server",
                              toast,
                            ),
                    ),
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: 'Tachidesk-Sorayomi',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlInWeb(
                              context,
                              "https://github.com/Suwayomi/Tachidesk-Sorayomi",
                              toast,
                            ),
                    ),
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: 'Tachiyomi-Extensions',
                      style: const TextStyle(color: Colors.blue),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrlInWeb(
                              context,
                              "https://github.com/tachiyomiorg/extensions",
                              toast,
                            ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              )),
          const Divider(),
        ],
      ),
    );
  }
}
