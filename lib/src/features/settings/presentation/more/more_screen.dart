// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/urls.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../widgets/server_url_tile/server_url_tile.dart';
import '../../widgets/theme_mode_tile/theme_mode_tile.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.more),
      ),
      body: ListView(
        children: [
          ImageIcon(
            AssetImage(Assets.icons.darkIcon.path),
            size: context.height * .2,
          ),
          const Divider(),
          const ServerUrlTile(),
          ListTile(
            title: Text(context.l10n!.categories),
            leading: const Icon(Icons.label_rounded),
            onTap: () => context.push([
              Routes.settings,
              Routes.librarySettings,
              Routes.editCategories
            ].toPath),
          ),
          const AppThemeTile(),
          ListTile(
            title: Text(context.l10n!.backup),
            leading: const Icon(Icons.settings_backup_restore_rounded),
            onTap: () => context.push([Routes.settings, Routes.backup].toPath),
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n!.settings),
            leading: const Icon(Icons.settings_rounded),
            onTap: () => context.push(Routes.settings),
          ),
          ListTile(
            title: Text(context.l10n!.about),
            leading: const Icon(Icons.info_rounded),
            onTap: () => context.push(Routes.about),
          ),
          ListTile(
            title: Text(context.l10n!.help),
            leading: const Icon(Icons.help_rounded),
            onTap: () => launchUrlInWeb(
              context,
              AppUrls.tachideskHelp.url,
              ref.read(toastProvider(context)),
            ),
          ),
        ],
      ),
    );
  }
}
