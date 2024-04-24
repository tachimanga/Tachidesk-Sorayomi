// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../constants/urls.dart';
import '../global_providers/global_providers.dart';
import '../routes/router_config.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/launch_url_in_web.dart';
import '../utils/misc/toast/toast.dart';
import '../utils/storage/dio_error_util.dart';
import 'emoticons.dart';

class CommonErrorWidget extends HookConsumerWidget {
  const CommonErrorWidget({
    super.key,
    this.refresh,
    this.showGenericError = false,
    this.src,
    this.webViewUrlProvider,
    required this.error,
  });
  final VoidCallback? refresh;
  final bool showGenericError;
  final Object error;
  final String? src;
  final Future<String?> Function()? webViewUrlProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final magic = ref.watch(getMagicProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final message = showGenericError
        ? context.l10n!.errorSomethingWentWrong
        : DioErrorUtil.localizeErrorMessage(error.toString(), context);
    final enableRefresh = useState(true);

    return Emoticons(
      text: message,
      button: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: refresh != null && enableRefresh.value
                ? () {
                    enableRefresh.value = false;
                    if (refresh != null) {
                      refresh!();
                    }
                    Timer(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        enableRefresh.value = true;
                      }
                    });
                  }
                : null,
            child: Column(children: [
              const Icon(Icons.refresh_rounded),
              Text(context.l10n!.refresh)
            ]),
          ),
          if (webViewUrlProvider != null) ...[
            TextButton(
              onPressed: () async {
                (await AsyncValue.guard(() async {
                  final url = await webViewUrlProvider!();
                  if (url.isBlank) {
                    throw Exception("Failed to get page url.");
                  }
                  if (context.mounted) {
                    context.push(Routes.getWebView(url ?? ""));
                  }
                }))
                    .showToastOnError(toast);
              },
              child: Column(children: [
                const Icon(Icons.public),
                Text(context.l10n!.webView)
              ]),
            )
          ],
          if (magic.b5) ...[
            TextButton(
              onPressed: () {
                final url = userDefaults.getString("config.findAnswerUrl") ??
                    AppUrls.findAnswer.url;
                launchUrlInWeb(
                  context,
                  "$url?src=${src ?? 'common'}&err=$message",
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
