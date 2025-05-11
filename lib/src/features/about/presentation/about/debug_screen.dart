// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:system_proxy/system_proxy.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/http_proxy.dart';
import '../../../../widgets/pop_button.dart';
import '../../../../widgets/text_field_popup.dart';
import '../../../browse_center/data/settings_repository/settings_repository.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../../manga_book/presentation/reader/controller/reader_controller_v2.dart';
import '../../../settings/presentation/advanced/widgets/useragent_select_tile.dart';
import '../../../settings/widgets/server_url_tile/server_url_tile.dart';
import '../../../stats/controller/stats_controller.dart';
import '../../../sync/controller/sync_controller.dart';
import 'controllers/about_controller.dart';
import 'widget/clipboard_list_tile.dart';
import 'widget/file_log_tile.dart';

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

    final remoteShowLogo = ref.watch(remoteShowLogoProvider);
    final localShowLogo = ref.watch(localShowLogoProvider);

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
        const Divider(),
        const ApiServerTile(),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("SyncWhenAppStart"),
          onChanged: ref.read(syncWhenAppStartPrefProvider.notifier).update,
          value: ref.watch(syncWhenAppStartPrefProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("SyncWhenAppResume"),
          onChanged: ref.read(syncWhenAppResumePrefProvider.notifier).update,
          value: ref.watch(syncWhenAppResumePrefProvider).ifNull(true),
        ),
        SyncPollingInterval(),
        SyncSampleInterval(),
        const Divider(),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("Use system proxy settings"),
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
        UserAgentSelectTile(),
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
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("localShowLogo"),
          onChanged: (value) async {
            ref.read(localShowLogoProvider.notifier).update(value);
          },
          value: localShowLogo == true,
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("remoteShowLogo"),
          onChanged: (value) async {
          },
          value: remoteShowLogo == true,
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
          title: Text("downscale image"),
          onChanged: ref.read(downscaleImageProvider.notifier).update,
          value: ref.watch(downscaleImageProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("downscale page image"),
          onChanged: ref.read(downscalePageProvider.notifier).update,
          value: ref.watch(downscalePageProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("auto refresh manga"),
          onChanged: ref.read(autoRefreshMangaProvider.notifier).update,
          value: ref.watch(autoRefreshMangaProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("show direct flag"),
          onChanged: ref.read(showDirectFlagPrefProvider.notifier).update,
          value: ref.watch(showDirectFlagPrefProvider).ifNull(true),
        ),
        SwitchListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: const Icon(Icons.switch_left_rounded),
          title: Text("show source url"),
          onChanged: ref.read(showSourceUrlProvider.notifier).update,
          value: ref.watch(showSourceUrlProvider).ifNull(true),
        ),
        ListTile(
          leading: const Icon(Icons.science),
          title: Text(context.l10n!.labs),
          subtitle: Text(context.l10n!.labsSubtitle),
          onTap: () => context.push([
            Routes.settings,
            Routes.generalSettings,
            Routes.labsSettings
          ].toPath),
        ),
      ]),
    );
  }
}


class ApiServerTile extends ConsumerWidget {
  const ApiServerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(cloudServerPrefProvider);
    return ListTile(
      leading: const Icon(Icons.computer_rounded),
      title: Text("Api Server URL"),
      subtitle: serverUrl.isNotBlank ? Text(serverUrl!) : null,
      onTap: () => showDialog(
        context: context,
        builder: (context) => ApiServerUrlField(initialUrl: serverUrl),
      ),
    );
  }
}

class ApiServerUrlField extends HookConsumerWidget {
  const ApiServerUrlField({
    this.initialUrl,
    super.key,
  });
  final String? initialUrl;

  void _update(String url, WidgetRef ref) async {
    final tempUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    ref.read(cloudServerPrefProvider.notifier).update(tempUrl);

    Map<String, String> map = {'cloudServer': tempUrl};
    String json = jsonEncode(map);
    await ref.read(settingsRepositoryProvider).uploadSettings(json: json);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: initialUrl);
    return AlertDialog(
      title: Text("Api Server URL"),
      content: TextField(
        autofocus: true,
        controller: controller,
        onSubmitted: (value) {
          _update(controller.text, ref);
          context.pop();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: ("Enter server url"),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            _update("http://127.0.0.1:8080", ref);
            context.pop();
          },
          child: Text("local"),
        ),
        ElevatedButton(
          onPressed: () {
            _update("http://192.168.0.42:4567", ref);
            context.pop();
          },
          child: Text("local2"),
        ),
        ElevatedButton(
          onPressed: () {
            _update("https://api3.tachimanga.app", ref);
            context.pop();
          },
          child: Text("api3"),
        ),
        const PopButton(),
        ElevatedButton(
          onPressed: () {
            _update(controller.text, ref);
            context.pop();
          },
          child: Text(context.l10n!.save),
        ),
      ],
    );
  }
}


class SyncPollingInterval extends ConsumerWidget {
  const SyncPollingInterval({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interval = ref.watch(syncPollingIntervalProvider);
    return ListTile(
      title: Text("SyncPollingInterval(need restart)"),
      subtitle: Text("$interval"),
      onTap: () => showDialog(
        context: context,
        builder: (context) => TextFieldPopup(
          title: "",
          onChange: (value) {
            ref.read(syncPollingIntervalProvider.notifier).update(int.parse(value));
            if (context.mounted) {
              context.pop();
            }
          },
          initialValue: "$interval",
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }
}


class SyncSampleInterval extends ConsumerWidget {
  const SyncSampleInterval({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    return ListTile(
      title: Text("SyncSampleInterval"),
      subtitle: Text("lost when restart"),
      onTap: () => showDialog(
        context: context,
        builder: (context) => TextFieldPopup(
          title: "",
          onChange: (value) async {
            Map<String, int> map = {'syncListenerInterval': int.parse(value)};
            String json = jsonEncode(map);
            await settingsRepository.uploadSettings(json: json);
            if (context.mounted) {
              context.pop();
            }
          },
          initialValue: "5",
          textInputAction: TextInputAction.done,
        ),
      ),
    );
  }
}
