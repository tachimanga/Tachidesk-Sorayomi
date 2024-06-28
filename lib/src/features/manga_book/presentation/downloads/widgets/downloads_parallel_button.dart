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

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/confirm_dialog.dart';
import '../../../../../widgets/info_list_tile.dart';
import '../../../../../widgets/premium_required_tile.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../browse_center/data/settings_repository/settings_repository.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../controller/downloads_controller.dart';

class DownloadsParallelButton extends HookConsumerWidget {
  const DownloadsParallelButton({
    super.key,
    required this.enable,
  });

  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(downloadTaskInParallelPrefProvider) ??
        DBKeys.downloadTaskInParallel.initial;
    return FilledButton.icon(
      onPressed: () {
        logEvent3("DOWNLOAD:PARALLEL:TAP:BUTTON");
        showDialog(
          context: context,
          builder: (context) => const DownloadsParallelDialog(),
        );
      },
      label: Text(context.l10n!.concurrent_download_short_title_num(limit)),
      icon: const Icon(Icons.bolt),
    );
  }
}

class DownloadsParallelSettingTile extends ConsumerWidget {
  const DownloadsParallelSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(downloadTaskInParallelPrefProvider) ??
        DBKeys.downloadTaskInParallel.initial;
    return ListTile(
      leading: const Icon(Icons.bolt),
      title: TextPremium(
        text: context.l10n!.concurrent_download_short_title,
      ),
      subtitle: Text("$limit"),
      onTap: () {
        logEvent3("DOWNLOAD:PARALLEL:TAP:TILE");
        showDialog(
          context: context,
          builder: (context) => const DownloadsParallelDialog(),
        );
      },
    );
  }
}

class DownloadsParallelDialog extends HookConsumerWidget {
  const DownloadsParallelDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(downloadTaskInParallelPrefProvider) ??
        DBKeys.downloadTaskInParallel.initial;
    final limitState = useState(limit);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    final toast = ref.watch(toastProvider(context));

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final premiumOption =
        !purchaseGate && !testflightFlag && limitState.value > 1;

    return ConfirmDialog(
      title: Text(context.l10n!.concurrent_download_title),
      content: RadioList(
        optionList: const [1, 2, 3, 4, 5],
        value: limitState.value,
        onChange: (value) {
          limitState.value = value;
        },
        displayName: (value) => "$value",
        additionWidgets: [
          if (premiumOption) ...[
            const PremiumRequiredTile(),
          ],
          if (!premiumOption && limitState.value > 1) ...[
            Text(
              context.l10n!.concurrent_download_tips,
              style: context.textTheme.bodySmall,
            )
          ],
        ],
      ),
      onConfirm: premiumOption
          ? null
          : () async {
              if (limitState.value > 1) {
                final confirmResult = await showDialog(
                    context: context,
                    builder: (ctx) {
                      return ConfirmDialog(
                        title: Text(context.l10n!.attention_label),
                        content: Text(context.l10n!.concurrent_download_tips),
                        onConfirm: () async {
                          ctx.pop(true);
                        },
                      );
                    });
                if (confirmResult != true) {
                  logEvent3("DOWNLOAD:PARALLEL:SET:CANCEL");
                  return;
                }
              }

              logEvent3("DOWNLOAD:PARALLEL:SET:VALUE_${limitState.value}");

              (await AsyncValue.guard(() async {
                final param =
                    jsonEncode({"downloadTaskInParallel": limitState.value});
                await settingsRepository.uploadSettings(json: param);
              }))
                  .showToastOnError(toast);

              ref
                  .read(downloadTaskInParallelPrefProvider.notifier)
                  .update(limitState.value);
              if (context.mounted) context.pop();
            },
    );
  }
}
