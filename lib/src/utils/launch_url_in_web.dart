// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/browse_center/data/browse_repository/browse_repository.dart';
import '../features/browse_center/domain/browse/browse_model.dart';
import '../routes/router_config.dart';
import 'extensions/custom_extensions.dart';
import 'misc/toast/toast.dart';

Future<void> launchUrlInWeb(BuildContext context, String url,
    [Toast? toast]) async {
  if (!await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.platformDefault,
    webOnlyWindowName: "_blank",
  )) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) toast?.showError(context.l10n!.errorLaunchURL(url));
  }
}

Future<void> launchUrlInSafari(BuildContext context, String url,
    [Toast? toast]) async {
  if (!await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
    webOnlyWindowName: "_blank",
  )) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) toast?.showError(context.l10n!.errorLaunchURL(url));
  }
}

Future<void> launchUrlInWebView(
  BuildContext context,
  WidgetRef ref,
  UrlFetchInput input,
) async {
  final message = context.l10n!.failed_to_get_url;
  final toast = ref.read(toastProvider(context));
  (await AsyncValue.guard(() async {
    final output =
        await ref.read(browseRepositoryProvider).fetchUrl(input: input);
    if (output == null || output.url.isNullOrEmpty) {
      throw Exception(message);
    }
    if (context.mounted) {
      context.push(Routes.goWebView, extra: output);
    }
  }))
      .showToastOnError(toast);
}
