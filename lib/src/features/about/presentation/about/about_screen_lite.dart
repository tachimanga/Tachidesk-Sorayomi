// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/urls.dart';

import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../data/about_repository.dart';
import '../../domain/about/about_model.dart';
import '../../domain/server_update/server_update_model.dart';
import 'controllers/about_controller.dart';
import 'widget/app_update_dialog.dart';
import 'widget/clipboard_list_tile.dart';
import 'widget/file_log_tile.dart';
import 'widget/media_launch_button.dart';

class AboutScreenLite extends HookConsumerWidget {
  const AboutScreenLite({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);

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
            value: "Tachimanga is an unofficial port of Tachiyomi for iOS, developed solely by @oldmike and has no affiliation with the original development team.",
          ),
          ClipboardListTile(
            title: "Credit",
            value: "This app is based on the following awesome projects: OpenJDK, Tachidesk-Server, Tachidesk-Sorayomi, Tachiyomi.",
          ),
          const Divider(),
          const FileLogTile(),
          const FileLogExport(),
          SwitchListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            secondary: const Icon(Icons.switch_left_rounded),
            title: Text("Native net for flutter (Need restart)"),
            onChanged: ref.read(useNativeNetProvider.notifier).update,
            value: ref.watch(useNativeNetProvider).ifNull(true),
          ),
        ],
      ),
    );
  }
}
