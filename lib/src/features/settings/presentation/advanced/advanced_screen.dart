// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_constants.dart';
import '../../../../constants/db_keys.dart';
import '../../../../constants/language_list.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/radio_list_popup.dart';
import '../../../../widgets/section_title.dart';
import '../../../about/presentation/about/widget/file_log_tile.dart';
import '../../../browse_center/data/settings_repository/settings_repository.dart';
import '../browse/widgets/bypass_setting/bypass_switch.dart';

class AdvancedScreen extends ConsumerWidget {
  const AdvancedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final toast = ref.watch(toastProvider(context));
    final magic = ref.watch(getMagicProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.advanced),
        actions: [
          TextButton(
            onPressed: () => _resetSettings(ref),
            child: Text(context.l10n!.reset),
          ),
        ],
      ),
      body: ListView(
        children: [
          SectionTitle(title: context.l10n!.dataUsageSectionTitle),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded),
            title: Text(context.l10n!.clearCache),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () async {
              toast.show("${context.l10n!.clearCache}...",
                  gravity: ToastGravity.CENTER,
                  toastDuration: const Duration(seconds: 30));
              try {
                await pipe.invokeMethod("CleanCache");
                log("CleanCache succ");
              } catch (e) {
                log("CleanCache err $e");
              }
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              toast.close();
              if (context.mounted) {
                toast.show(context.l10n!.cacheCleared,
                    gravity: ToastGravity.CENTER);
              }
            },
          ),
          SectionTitle(title: context.l10n!.networkSectionTitle),
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded),
            title: Text(context.l10n!.clearCookies),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () async {
              toast.show("${context.l10n!.clearCookies}...",
                  gravity: ToastGravity.CENTER,
                  toastDuration: const Duration(seconds: 30));
              try {
                await pipe.invokeMethod("ClearCookies");
                await settingsRepository.clearCookies();
                log("clearCookies succ");
              } catch (e) {
                log("clearCookies err $e");
              }
              toast.close();
              if (context.mounted) {
                toast.show(context.l10n!.cookiesCleared,
                    gravity: ToastGravity.CENTER);
              }
            },
          ),
          if (magic.b7) ...[
            const ByPassTile(),
          ],
          const ReceiveTimeoutTile(),
          SectionTitle(title: context.l10n!.logsSectionTitle),
          const FileLogTile(),
          const FileLogExport(),
        ],
      ),
    );
  }

  void _resetSettings(WidgetRef ref) {
    ref
        .read(byPassSwitchProvider.notifier)
        .update(DBKeys.disableBypass.initial);
    ref.read(fileLogProvider.notifier).update(DBKeys.enableFileLog.initial);
  }
}

class ReceiveTimeoutTile extends ConsumerWidget {
  const ReceiveTimeoutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = [20, 30, 40];
    final timeout = ref.watch(receiveTimeoutPrefProvider) ?? options[0];

    return ListTile(
      leading: const Icon(Icons.timer_sharp),
      title: Text(context.l10n!.receive_timeout_label),
      subtitle: Text("${timeout}s"),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<int>(
          title: context.l10n!.receive_timeout_label,
          subTitle: context.l10n!.receive_timeout_subtitle,
          optionList: options,
          optionDisplayName: (value) => "${value}s",
          value: timeout,
          onChange: (value) async {
            logEvent3("SETTING:NETWORK:RECEIVE:TIMEOUT", {"x" : "$value"});
            ref.read(receiveTimeoutPrefProvider.notifier).update(value);
            final dioClient = ref.read(dioClientKeyProvider);
            dioClient.dio.options.receiveTimeout = Duration(seconds: value);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
