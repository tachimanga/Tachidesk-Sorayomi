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

import '../../../../../constants/app_sizes.dart';

import '../../../../../constants/urls.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../utils/storage/dio_error_util.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../domain/source/source_model.dart';

class SourcePageErrorView extends ConsumerWidget {
  const SourcePageErrorView({super.key, required this.controller, this.source, this.message});
  final PagingController<int, Manga> controller;
  final Source? source;
  final String? message;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final magic = ref.watch(getMagicProvider);
    final rawMessage = this.message ?? controller.error.toString();
    final message = DioErrorUtil.localizeErrorMessage(rawMessage, context);
    return Emoticons(
      text: message,
      button: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => controller.refresh(),
            child: Column(
                children: [
                  const Icon(Icons.replay_rounded),
                  Text(context.l10n!.retry)
                ]
            ),
          ),
          if (source?.baseUrl?.isNotEmpty ?? false) ...[
            TextButton(
              onPressed: () {
                context.push(Routes.getWebView(source?.baseUrl ?? ""));
                final pkgName = source?.extPkgName?.replaceAll("eu.kanade.tachiyomi.extension.", "");
                pipe.invokeMethod("LogEvent", "BYPASS_$pkgName");
              },
              child: Column(
                  children: [
                    const Icon(Icons.public),
                    Text("WebView")
                  ]
              ),
            )
          ],
          if (magic.b5) ...[
            TextButton(
              onPressed: () {
                final url = userDefaults.getString("config.findAnswerUrl") ??
                    AppUrls.findAnswer.url;
                launchUrlInWeb(
                  context,
                  "$url?source=${source?.name}&ext=${source?.extPkgName}&err=${message}",
                  ref.read(toastProvider(context)),
                );
              },
              child: Column(
                  children: [
                    const Icon(Icons.help_rounded),
                    Text(context.l10n!.help)
                  ]
              ),
            )
          ],
        ],
      ),
    );
  }
}
