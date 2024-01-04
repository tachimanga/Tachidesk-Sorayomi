// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/gen/assets.gen.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import 'controllers/about_controller.dart';
import 'widget/clipboard_list_tile.dart';

class AboutScreenLite extends HookConsumerWidget {
  const AboutScreenLite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final toast = ref.watch(toastProvider(context));

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
          ClipboardListTile(
            title: context.l10n!.clientVersion,
            value: "v${packageInfo.version}(${packageInfo.buildNumber})",
          ),
          ClipboardListTile(
            title: "About",
            value:
                "Tachimanga is an unofficial port of Tachiyomi for iOS, developed solely by @oldmike and has no affiliation with the original development team.",
          ),
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
                              "https://github.com/tachiyomiorg/tachiyomi-extensions",
                              toast,
                            ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
