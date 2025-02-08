// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/urls.dart';
import '../../routes/router_config.dart';
import '../../utils/event_util.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/launch_url_in_web.dart';
import '../../utils/log.dart';
import '../../utils/misc/toast/toast.dart';
import '../../utils/string_util.dart';
import 'controller/account_controller.dart';
import 'data/account_repository.dart';
import 'domain/account_model.dart';
import 'widgets/login_terms_widget.dart';

class AccountLoginScreen extends HookConsumerWidget {
  const AccountLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final accountRepository = ref.watch(accountRepositoryProvider);

    final email = useState("");
    final password = useState("");

    final errorMsg = useState("");
    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.login),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: context.l10n!.email),
              onChanged: (value) => email.value = value.trim(),
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(labelText: context.l10n!.password),
              onChanged: (value) => password.value = value,
              obscureText: true,
            ),
            if (errorMsg.value.isNotEmpty) ...[
              Text(
                errorMsg.value,
                style:
                    context.textTheme.labelLarge?.copyWith(color: Colors.red),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  log('Login Email: ${email.value}, Password: ${password.value}');
                  if (email.value.isEmpty || !isValidEmail(email.value)) {
                    errorMsg.value = context.l10n!.email_empty;
                    return;
                  }
                  if (password.value.isEmpty) {
                    errorMsg.value = context.l10n!.password_empty;
                    return;
                  }
                  logEvent3("USER:TAP:LOGIN");
                  isLoading.value = true;
                  FocusManager.instance.primaryFocus?.unfocus();
                  (await AsyncValue.guard(
                    () async {
                      await accountRepository.login(
                          param: UserLoginInput(
                              email: email.value, password: password.value));
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
                child: isLoading.value
                    ? Text(context.l10n!.processing)
                    : Text(context.l10n!.login),
              ),
            ),
            const SizedBox(height: 10),
            const LoginTermsWidget(),
            const SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: context.textTheme.bodyMedium,
                children: [
                  TextSpan(text: context.l10n!.do_not_have_account),
                  const TextSpan(text: " "),
                  TextSpan(
                    text: context.l10n!.register_here,
                    style:
                        const TextStyle(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.replace(Routes.userRegister);
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
