// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/event_util.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/log.dart';
import '../../../utils/misc/toast/toast.dart';
import '../../sync/data/sync_repository.dart';
import '../controller/account_controller.dart';
import '../data/account_repository.dart';
import '../domain/account_model.dart';

class SignInWithAppleWidget extends HookConsumerWidget {
  const SignInWithAppleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final accountRepository = ref.watch(accountRepositoryProvider);

    final isLoading = useState(false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SignInWithAppleButton(
        text: isLoading.value
            ? context.l10n!.processing
            : context.l10n!.sign_in_with_apple,
        style: context.isDarkMode
            ? SignInWithAppleButtonStyle.white
            : SignInWithAppleButtonStyle.black,
        onPressed: () async {
          logEvent3("USER:LOGIN:APPLE");
          isLoading.value = true;
          (await AsyncValue.guard(
            () async {
              final credential = await SignInWithApple.getAppleIDCredential(
                scopes: [
                  AppleIDAuthorizationScopes.fullName,
                  AppleIDAuthorizationScopes.email,
                ],
              );
              log("SignInWithAppleButton result=$credential authorizationCode=${credential.authorizationCode} identityToken=${credential.identityToken}");

              await accountRepository.thirdLogin(
                param: ThirdLoginInput(
                  type: "APPLE",
                  thirdUserId: credential.userIdentifier,
                  token: credential.identityToken,
                  userName: credential.givenName,
                ),
              );

              ref.refresh(userInfoProvider.future);
              final now = DateTime.now().millisecondsSinceEpoch;
              ref.read(userLoginSignalProvider.notifier).update(now);
              if (context.mounted) {
                context.pop();
              }
            },
          ))
              .showToastOnError(toast);
          if (context.mounted) {
            isLoading.value = false;
          }
        },
      ),
    );
  }
}
