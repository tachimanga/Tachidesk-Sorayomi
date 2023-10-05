// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:system_proxy/system_proxy.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/urls.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/http_proxy.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../browse_center/data/settings_repository/settings_repository.dart';
import '../../../settings/widgets/server_url_tile/server_url_tile.dart';
import '../../data/about_repository.dart';
import '../../domain/about/about_model.dart';
import '../../domain/server_update/server_update_model.dart';
import 'controllers/about_controller.dart';
import 'widget/app_update_dialog.dart';
import 'widget/clipboard_list_tile.dart';
import 'widget/file_log_tile.dart';
import 'widget/media_launch_button.dart';

class DebugScreen extends HookConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final javaUseNativeNet = ref.watch(javaUseNativeNetProvider).ifNull(false);
    final sourceDirect = useState(false);
    return Scaffold(
      appBar: AppBar(
        title: Text("Debug"),
      ),
      body: ListView(children: [
        ClipboardListTile(
          title: context.l10n!.clientVersion,
          value: "v${packageInfo.version}(${packageInfo.buildNumber})",
        ),
        const FileLogTile(),
        const FileLogExport(),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text(context.l10n!.useSysProxy),
          onChanged: (value) async {
            ref.read(useSystemProxyProvider.notifier).update(value);
            final proxy = await SystemProxy.getProxySettings();
            configHttpClient(proxy, value);
          },
          value: ref.watch(useSystemProxyProvider).ifNull(),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("Native net for flutter (Need restart)"),
          onChanged: ref.read(useNativeNetProvider.notifier).update,
          value: ref.watch(useNativeNetProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("Native net for java"),
          onChanged: (value) async {
            Map<String, bool> map = {'enableNativeNet': value};
            String json = jsonEncode(map);
            await settingsRepository.uploadSettings(json: json);
            ref.read(javaUseNativeNetProvider.notifier).update(value);
          },
          value: javaUseNativeNet,
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("disable direct"),
          onChanged: (value) async {
            Map<String, bool> map = {'enableFlutterDirect': !value};
            String json = jsonEncode(map);
            await settingsRepository.uploadSettings(json: json);
            sourceDirect.value = value;
          },
          value: sourceDirect.value,
        ),
        const ServerUrlTile(),
      ]),
    );
  }
}
