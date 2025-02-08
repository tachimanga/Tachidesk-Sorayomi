// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/urls.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/launch_url_in_web.dart';
import '../../../utils/misc/toast/toast.dart';

class LoginTermsWidget extends HookConsumerWidget {
  const LoginTermsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    const placeholder = "###";
    final text = context.l10n!.login_term(placeholder, placeholder);
    final parts = text.split(placeholder);
    final style = context.textTheme.bodySmall?.copyWith(
      color: Colors.grey,
      fontSize: 10,
    );
    if (parts.length != 3) {
      return Text(
        context.l10n!.login_term(
          context.l10n!.privacyUrl,
          context.l10n!.termsUrl,
        ),
        style: style,
      );
    }
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: context.l10n!.termsUrl,
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlInWeb(context, AppUrls.terms.url, toast),
          ),
          TextSpan(text: parts[1]),
          TextSpan(
            text: context.l10n!.privacyUrl,
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap =
                  () => launchUrlInWeb(context, AppUrls.privacy.url, toast),
          ),
          TextSpan(text: parts[2]),
        ],
      ),
    );
  }
}
