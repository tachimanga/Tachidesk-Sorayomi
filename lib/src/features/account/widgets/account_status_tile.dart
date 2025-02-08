// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/log.dart';
import '../../../utils/misc/toast/toast.dart';
import '../controller/account_controller.dart';
import '../data/account_repository.dart';
import '../domain/account_model.dart';

class AccountStatusTile extends HookConsumerWidget {
  const AccountStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userInfoValue = ref.watch(userInfoProvider);
    final userInfo = userInfoValue.valueOrNull;
    EdgeInsets windowPadding = MediaQuery.paddingOf(context);

    return ListTile(
      leading: const Icon(Icons.account_circle_sharp),
      title: userInfo?.name?.isNotEmpty == true
          ? Text(userInfo?.name ?? "")
          : Text(userInfo?.email ?? ""),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: context.theme.cardColor,
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: windowPadding.bottom),
            child: AccountBottomSheet(outerContext: context),
          ),
        );
      },
    );
  }
}

class AccountBottomSheet extends HookConsumerWidget {
  const AccountBottomSheet({
    super.key,
    required this.outerContext,
  });

  final BuildContext outerContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        ListTile(
          title: Text(
            context.l10n!.logout,
            style: context.textTheme.labelLarge?.copyWith(color: Colors.red),
          ),
          onTap: () {
            context.pop();
            showDialog(
              context: outerContext,
              builder: (ctx) => const LogoutDialog(),
            );
          },
        ),
        ListTile(
          title: Text(
            context.l10n!.delete_account_label,
            style: context.textTheme.labelLarge?.copyWith(color: Colors.red),
          ),
          onTap: () {
            context.pop();
            showDialog(
              context: outerContext,
              builder: (ctx) => const DeleteAccountDialog(),
            );
          },
        ),
        ListTile(
          title: Text(
            context.l10n!.cancel,
            style: context.textTheme.labelLarge,
          ),
          onTap: () {
            context.pop();
          },
        ),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }
}

class LogoutDialog extends HookConsumerWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final accountRepository = ref.watch(accountRepositoryProvider);

    final logoutAll = useState(false);

    return AlertDialog(
      title: Text(context.l10n!.logoutFrom(context.l10n!.appTitle)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoutAll.value
              ? Text(context.l10n!.logout_all_tips)
              : Text(context.l10n!.logout_tips),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: logoutAll.value,
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  logoutAll.value = value == true;
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    logoutAll.value = !logoutAll.value;
                  },
                  child: Text(context.l10n!.logout_all),
                ),
              ),
            ],
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n!.cancel),
            ),
            const SizedBox(width: 15),
            TextButton(
              onPressed: () async {
                final param = UserLogoutInput(logoutAll: logoutAll.value);
                (await AsyncValue.guard(() async {
                  await accountRepository.logout(param: param);
                }))
                    .showToastOnError(toast);
                ref.refresh(userInfoProvider.future);
                if (context.mounted) {
                  context.pop();
                }
              },
              child: Text(context.l10n!.logout),
            ),
          ],
        ),
      ],
    );
  }
}

class DeleteAccountDialog extends HookConsumerWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final accountRepository = ref.watch(accountRepositoryProvider);
    const confirmText = "delete my account";
    final confirmController = useTextEditingController();
    return AlertDialog(
      title: Text(context.l10n!.delete_account_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n!.delete_account_verify(confirmText),
            style: context.textTheme.bodyMedium,
          ),
          const SizedBox(height: 5),
          TextField(
            controller: confirmController,
            autofocus: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: confirmText,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n!.delete_account_content,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(context.l10n!.cancel),
            ),
            const SizedBox(width: 15),
            TextButton(
              onPressed: () async {
                if (confirmController.text != confirmText) {
                  toast.showError(
                      context.l10n!.delete_account_verify(confirmText));
                  return;
                }
                final pass = await checkBiometrics(context, toast);
                if (!pass) {
                  log("checkBiometrics not pass");
                  return;
                }
                (await AsyncValue.guard(() async {
                  await accountRepository.delete(param: UserDeleteInput());
                }))
                    .showToastOnError(toast);
                ref.refresh(userInfoProvider.future);
                if (context.mounted) {
                  context.pop();
                }
              },
              child: Text(context.l10n!.delete_account_label),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> checkBiometrics(BuildContext context, Toast toast) async {
    try {
      final errMsg = context.l10n!.lock_biometrics_unavailable;
      final unlockTitle = context.l10n!.unlock_title;
      final auth = LocalAuthentication();
      final availableBiometrics = await auth.getAvailableBiometrics();
      log("availableBiometrics $availableBiometrics");
      if (availableBiometrics.isEmpty) {
        toast.showError(errMsg);
        return false;
      }
      final bool didAuthenticate =
          await auth.authenticate(localizedReason: unlockTitle);
      log("didAuthenticate $didAuthenticate");
      if (!didAuthenticate) {
        toast.showError(errMsg);
        return false;
      }
      return true;
    } on PlatformException catch (e) {
      toast.showError("${e.message}");
      return false;
    }
  }
}
