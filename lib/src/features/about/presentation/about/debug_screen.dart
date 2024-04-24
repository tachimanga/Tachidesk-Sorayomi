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
import '../../../custom/inapp/purchase_providers.dart';
import '../../../manga_book/presentation/reader/controller/reader_controller_v2.dart';
import '../../../settings/presentation/browse/widgets/repo_setting/repo_url_tile.dart';
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
    final disableStopSocketV2 = ref.watch(disableStopSocketV2Provider);
    final sourceDirect = useState(false);
    final pipe = ref.watch(getMagicPipeProvider);

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
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("enable stopSocketV2"),
          onChanged: (value) async {
            ref.read(disableStopSocketV2Provider.notifier).update(value ? "" : "1");
          },
          value: disableStopSocketV2 != "1",
        ),
        ListTile(
            title: Text("crash"),
            leading: const Icon(Icons.bug_report),
            onTap: () {
              pipe.invokeMethod("LogEvent", -1);
            }),
        /*
        ListTile(
            title: Text("set purchase"),
            leading: const Icon(Icons.bug_report),
            onTap: () {
              ref.read(purchaseDoneProvider.notifier).update(true);
              ref.read(purchaseExpireMsProvider.notifier).update(-1);
            }),
        ListTile(
            title: Text("clear purchase"),
            leading: const Icon(Icons.bug_report),
            onTap: () {
              ref.read(purchaseDoneProvider.notifier).update(false);
              ref.read(purchaseExpireMsProvider.notifier).update(0);
            }),
         */
        const RepoUrlTile(),
        ListTile(
            title: Text("clean ad mem"),
            leading: const Icon(Icons.cleaning_services_rounded),
            onTap: () {
              pipe.invokeMethod("CLEAN_AD_MEM_FOR_DEBUG");
            }),
        ListTile(
            title: Text("req ad"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              final r = await pipe.invokeMethod("REQUEST_AD");
              print(r);
            }),
        ListTile(
            title: Text("test rate"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              final r = await pipe.invokeMethod("TEST_RATE");
              print(r);
            }),
        ListTile(
            title: Text("GDPR SETTING"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              final r = await pipe.invokeMethod("AD:GDPR:SETTING");
              print(r);
            }),
        ListTile(
            title: Text("GDPR RESET"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              final r = await pipe.invokeMethod("AD:GDPR:RESET");
              print(r);
            }),
        ListTile(
            title: Text("purchase"),
            leading: const Icon(Icons.star_rounded),
            onTap: () {
              context.push(Routes.purchase);
            }),
        ListTile(
            title: Text("FLEX"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              pipe.invokeMethod("SHOW_FLEX");
            }),
        ListTile(
            title: Text("SANDBOX"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              pipe.invokeMethod("SHOW_SANDBOX");
            }),
        ListTile(
            title: Text("REPORT_INFO"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              pipe.invokeMethod("REPORT_INFO");
            }),
        ListTile(
            title: Text("Keyboard"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              context.push([Routes.settings, 's-keyboard'].toPath);
            }),
        ListTile(
            title: Text("clear premium"),
            leading: const Icon(Icons.send_rounded),
            onTap: () async {
              ref.read(purchaseDoneProvider.notifier).update(false);
              ref.read(purchaseExpireMsProvider.notifier).update(null);

            }),
        // ListTile(
        //     title: Text("BACKUP:LIST"),
        //     leading: const Icon(Icons.send_rounded),
        //     onTap: () async {
        //       final r = await pipe.invokeMethod("BACKUP:LIST");//map
        //       print(r);
        //     }),
        // ListTile(
        //     title: Text("BACKUP:CREATE"),
        //     leading: const Icon(Icons.send_rounded),
        //     onTap: () async {
        //       final r = await pipe.invokeMethod("BACKUP:CREATE");
        //       print(r);
        //     }),
        // ListTile(
        //     title: Text("BACKUP:RESTORE"),
        //     leading: const Icon(Icons.send_rounded),
        //     onTap: () async {
        //       final r = await pipe.invokeMethod("BACKUP:RESTORE",
        //           {"name": "Tachimanga_backup_20231105_000208951",
        //             "path": "",
        //             "autoBackup": "1"});
        //       print(r);
        //     }),
        // ListTile(
        //     title: Text("BACKUP:EXPORT"),
        //     leading: const Icon(Icons.send_rounded),
        //     onTap: () async {
        //       final r = await pipe.invokeMethod("BACKUP:EXPORT",
        //           {"name": "Tachimanga_backup_20231105_000208951"});
        //       print(r);
        //     }),
        // ListTile(
        //     title: Text("BACKUP:DELETE"),
        //     leading: const Icon(Icons.send_rounded),
        //     onTap: () async {
        //       final r = await pipe.invokeMethod("BACKUP:DELETE",
        //           {"id": 1});
        //       print(r);
        //     }),
        const ServerUrlTile(),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("enable ReaderV2"),
          onChanged: ref.read(useReader2Provider.notifier).update,
          value: ref.watch(useReader2Provider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("downscale image"),
          onChanged: ref.read(downscaleImageProvider.notifier).update,
          value: ref.watch(downscaleImageProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("show direct flag"),
          onChanged: ref.read(showDirectFlagPrefProvider.notifier).update,
          value: ref.watch(showDirectFlagPrefProvider).ifNull(true),
        ),
      ]),
    );
  }
}
