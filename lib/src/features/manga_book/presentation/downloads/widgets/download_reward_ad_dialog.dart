// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../custom/ads/controller/reward_ads_controller.dart';
import '../service/download_ticket_service.dart';

Future<void> showAdDialogIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required int chaptersCount,
  required Future<void> Function() onPass,
}) async {
  ref.read(downloadTicketServiceProvider.notifier).preloadAd();

  final succ = ref
      .read(downloadTicketServiceProvider.notifier)
      .decreaseTicket(chaptersCount);
  if (succ) {
    log("[AD][DOWNLOAD]enough tickets, exec onPass");
    await onPass();
    return;
  }
  if (!context.mounted) {
    return;
  }

  final completer = Completer<Pair<bool, bool>>();
  showDialog(
    context: context,
    builder: (context) {
      return DownloadRewardAdDialog(
        title: context.l10n!.download_limit_exceeded_title,
        onDismiss: (bool reward, bool skip) {
          log("[AD][DOWNLOAD]DownloadRewardAdDialog onDismiss reward:$reward, skip:$skip");
          completer.complete(Pair(first: reward, second: skip));
        },
      );
    },
  );

  final pair = await completer.future;
  final reward = pair.first;
  final skip = pair.second;
  if (reward) {
    final succ = ref
        .read(downloadTicketServiceProvider.notifier)
        .decreaseTicket(chaptersCount);
    if (succ) {
      log("[AD][DOWNLOAD]reward and enough tickets, exec onPass");
      await onPass();
    } else {
      log("[AD][DOWNLOAD]reward and not enough tickets, skip");
    }
  } else if (skip) {
    log("[AD][DOWNLOAD]skip ad, exec onPass");
    await onPass();
  } else {
    log("[AD][DOWNLOAD]not reward, skip");
  }
}

class DownloadRewardAdDialog extends HookConsumerWidget {
  const DownloadRewardAdDialog({
    super.key,
    required this.title,
    required this.onDismiss,
  });

  final String title;
  final CompleteCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final toast = ref.watch(toastProvider(context));
    final config = ref.read(rewardAdsConfigProvider);
    final rewardText =
        context.l10n!.download_limit_increase(config.ticketPerAd ?? 0);
    return AlertDialog(
      title: Text(title),
      content: Text(context.l10n!.download_limit_content(
        config.freeTicket ?? 0,
        config.maxAds ?? 0,
        config.ticketPerAd ?? 0,
      )),
      actions: [
        TextButton(
          onPressed: isLoading.value
              ? null
              : () async {
                  logEvent3("REWARD:TAP:WATCH");
                  isLoading.value = true;
                  (await AsyncValue.guard(() async {
                    await ref
                        .read(downloadTicketServiceProvider.notifier)
                        .showAd(onDismiss, rewardText);
                    if (context.mounted) {
                      context.pop();
                    }
                  }))
                      .showToastOnError(toast);
                  isLoading.value = false;
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isLoading.value)
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              if (isLoading.value)
                const SizedBox(
                  width: 4,
                ),
              Text(context.l10n!.watch_ad_label),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            logEvent3("REWARD:TAP:PREMIUM");
            onDismiss(false, false);
            context.push(Routes.purchase);
            context.pop();
          },
          child: Text(context.l10n!.getPremium),
        ),
        TextButton(
          onPressed: () {
            logEvent3("REWARD:TAP:CANCEL");
            onDismiss(false, false);
            context.pop();
          },
          child: Text(context.l10n!.cancel),
        ),
      ],
    );
  }
}
