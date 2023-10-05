// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../constants/urls.dart';
import '../global_providers/global_providers.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/launch_url_in_web.dart';
import '../utils/misc/toast/toast.dart';
import 'emoticons.dart';

class CommonErrorWidget extends ConsumerWidget {
  const CommonErrorWidget({
    super.key,
    this.refresh,
    this.showGenericError = false,
    required this.error,
  });
  final VoidCallback? refresh;
  final bool showGenericError;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final message = showGenericError
        ? context.l10n!.errorSomethingWentWrong
        : error.toString();

    return Emoticons(
      text: message,
      button: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: refresh,
            child: Column(children: [
              const Icon(Icons.refresh_rounded),
              Text(context.l10n!.refresh)
            ]),
          ),
          if (magic.b5) ...[
            TextButton(
              onPressed: () {
                final url = userDefaults.getString("config.findAnswerUrl") ??
                    AppUrls.findAnswer.url;
                launchUrlInWeb(
                  context,
                  "$url?src=common&err=$message",
                  ref.read(toastProvider(context)),
                );
              },
              child: Column(children: [
                const Icon(Icons.help_rounded),
                Text(context.l10n!.help)
              ]),
            )
          ],
        ],
      ),
    );
  }
}
