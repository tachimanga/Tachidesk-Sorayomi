// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/app_constants.dart';
import '../../constants/urls.dart';
import '../../routes/router_config.dart';
import '../../utils/event_util.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/launch_url_in_web.dart';
import '../../utils/log.dart';
import '../../utils/misc/toast/toast.dart';
import '../../widgets/banner/notice_banner.dart';
import '../../widgets/confirm_dialog.dart';
import '../account/controller/account_controller.dart';
import '../account/widgets/login_terms_widget.dart';
import '../account/widgets/signin_with_apple.dart';
import '../custom/inapp/purchase_providers.dart';
import '../settings/presentation/backup2/controller/backup_controller.dart';
import 'controller/sync_controller.dart';
import 'data/sync_repository.dart';
import 'domain/sync_model.dart';
import 'widgets/sync_now_tile.dart';

class SyncSettingsScreen extends HookConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final syncNoticeInfoValue = ref.watch(syncNoticeInfoProvider);
    final syncNoticeInfo = syncNoticeInfoValue.valueOrNull?.data?.syncInfo;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final premium = purchaseGate || testflightFlag;

    final userInfoValue = ref.watch(userInfoProvider);
    final userInfo = userInfoValue.valueOrNull;

    final userLoginSignal = ref.watch(userLoginSignalProvider);
    final statusValue = ref.watch(syncSocketProvider);
    final syncStatus = statusValue.valueOrNull;

    useEffect(() {
      promptToEnableSyncIfNeed(context, ref, userLoginSignal, syncStatus);
      return;
    }, [userLoginSignal]);

    useEffect(() {
      pipe.invokeMethod("SCREEN_ON", "1");
      return () {
        pipe.invokeMethod("SCREEN_ON", "0");
      };
    }, []);

    useEffect(() {
      Future(() {
        ref.invalidate(syncSocketProvider);
      });
      return;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.sync),
        actions: [
          IconButton(
            onPressed: () =>
                launchUrlInWeb(context, AppUrls.syncHelp.url, toast),
            icon: const Icon(Icons.help_rounded),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (syncNoticeInfo != null && syncNoticeInfo.notice?.isNotEmpty == true) ...[
            NoticeBanner(
              content: Text(syncNoticeInfo.notice ?? ""),
              action: syncNoticeInfo.button != null
                  ? BannerAction(
                      text: syncNoticeInfo.button?.text ?? "",
                      onPress: () {
                        final link = syncNoticeInfo.button?.link;
                        if (link?.isNotEmpty == true) {
                          launchUrlInWeb(context, link ?? "", toast);
                        }
                      },
                    )
                  : null,
            ),
          ],
          if (premium && userInfo?.login != true) ...[
            const EnableSyncTile(),
          ],
          if (premium && userInfo?.login == true) ...[
            const SyncSwitchTile(),
            const SyncNowTile(),
          ],
          if (!premium) ...[
            const SubscribeToEnableTile(),
          ],
          const Divider(),
          FaqListTile(
            title: context.l10n!.sync_faq_q1,
            subTitle: context.l10n!.sync_faq_a1,
          ),
          FaqListTile(
            title: context.l10n!.sync_faq_q2,
            subTitle: context.l10n!.sync_faq_a2,
          ),
          FaqListTile(
            title: context.l10n!.sync_faq_q3,
            subTitle: context.l10n!.sync_faq_a3,
          ),
          FaqListTile(
            title: context.l10n!.sync_faq_q4,
            subTitle: context.l10n!.sync_faq_a4,
          ),
          FaqListTile(
            title: context.l10n!.sync_faq_q5,
            subTitle: context.l10n!.sync_faq_a5,
          ),
        ],
      ),
    );
  }

  void promptToEnableSyncIfNeed(
    BuildContext context,
    WidgetRef ref,
    int? userLoginSignal,
    SyncStatus? syncStatus,
  ) {
    log("promptToEnableSyncIfNeed userLoginSignal=$userLoginSignal enable=$syncStatus");
    if (userLoginSignal != null &&
        userLoginSignal > 0 &&
        syncStatus?.enable != true) {
      Future(() {
        showDialog(
          context: context,
          builder: (context) => const EnableSyncDialog(),
        );
      });
    }
  }
}

class EnableSyncDialog extends HookConsumerWidget {
  const EnableSyncDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final syncRepository = ref.watch(syncRepositoryProvider);

    final step = useState(1);
    final autoBackup = useState(true);
    final isLoading = useState(false);

    if (step.value == 1 || step.value == 2) {
      return ConfirmDialog(
        title: Text(context.l10n!.enable_sync),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            step.value == 1
                ? Text(context.l10n!.enable_sync_tip)
                : Text(context.l10n!.enable_sync_up_to_date_tip),
            const SizedBox(height: 20),
            Text(context.l10n!.are_you_sure_proceed),
          ],
        ),
        confirmText: context.l10n!.next,
        onConfirm: () async {
          step.value = step.value + 1;
        },
      );
    }

    return ConfirmDialog(
      title: Text(context.l10n!.enable_sync),
      content: Row(
        children: [
          Checkbox(
            value: autoBackup.value,
            onChanged: (value) {
              autoBackup.value = value == true;
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                autoBackup.value = !autoBackup.value;
              },
              child: Text(context.l10n!.create_backup_before_enable_sync),
            ),
          ),
        ],
      ),
      confirmText: isLoading.value
          ? context.l10n!.processing
          : context.l10n!.enable_sync,
      onConfirm: () async {
        logEvent3("SYNC:ENABLE");
        context.pop();
        isLoading.value = true;
        if (autoBackup.value) {
          await AsyncValue.guard(() async {
            try {
              await ref.read(backupActionProvider).createBackup({}, type: 1);
            } catch (e) {
              log("create backup before sync error:$e");
            }
          });
        }
        (await AsyncValue.guard(
          () async {
            await syncRepository.enableSync();
          },
        ))
            .showToastOnError(toast);
        isLoading.value = false;
      },
    );
  }
}

class EnableSyncTile extends HookConsumerWidget {
  const EnableSyncTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    EdgeInsets windowPadding = MediaQuery.paddingOf(context);
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Text(context.l10n!.login_to_enable_sync),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: context.theme.cardColor,
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: windowPadding.bottom),
            child: const LoginBottomSheet(),
          ),
        );
      },
    );
  }
}

class SubscribeToEnableTile extends HookConsumerWidget {
  const SubscribeToEnableTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Text(context.l10n!.subscribe_to_enable_sync),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        logEvent3("SYNC:ENABLE:GATE");
        context.push(Routes.purchase);
      },
    );
  }
}

class SyncSwitchTile extends HookConsumerWidget {
  const SyncSwitchTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final syncRepository = ref.watch(syncRepositoryProvider);

    final statusValue = ref.watch(syncSocketProvider);
    final status = statusValue.valueOrNull;
    final enable = status?.enable == true;

    log("[SYNC]syncSocket enable:$enable status:$status");

    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.cloud_outlined),
      title: Text(context.l10n!.sync),
      contentPadding: kSettingPadding,
      onChanged: (value) async {
        (await AsyncValue.guard(
          () async {
            if (value) {
              if (status?.enableBefore == true) {
                logEvent3("SYNC:ENABLE:AGAIN");
                await syncRepository.enableSync();
              } else {
                showDialog(
                  context: context,
                  builder: (context) => const EnableSyncDialog(),
                );
              }
            } else {
              logEvent3("SYNC:DISABLE");
              await syncRepository.disableSync();
            }
          },
        ))
            .showToastOnError(toast);
      },
      value: enable,
    );
  }
}

class LoginBottomSheet extends HookConsumerWidget {
  const LoginBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        const SizedBox(height: 15),
        const SignInWithAppleWidget(),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: TextButton(
            onPressed: () {
              logEvent3("USER:LOGIN:EMAIL");
              context.pop();
              context.push(Routes.userLogin);
            },
            child: Text(
              context.l10n!.login_with_email,
              style: context.textTheme.titleSmall,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: LoginTermsWidget(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class FaqListTile extends HookConsumerWidget {
  const FaqListTile({
    super.key,
    required this.title,
    required this.subTitle,
  });

  final String title;
  final String subTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(
        title,
        style: context.textTheme.bodySmall,
      ),
      subtitle: Text(
        subTitle,
        style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      dense: true,
    );
  }
}
