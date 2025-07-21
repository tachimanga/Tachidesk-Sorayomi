// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../constants/urls.dart';
import '../features/browse_center/data/browse_repository/browse_repository.dart';
import '../features/browse_center/domain/browse/browse_model.dart';
import '../features/manga_book/data/manga_book_repository.dart';
import '../features/manga_book/presentation/manga_details/controller/manga_details_controller.dart';
import '../global_providers/global_providers.dart';
import '../icons/icomoon_icons.dart';
import '../routes/route_params.dart';
import '../routes/router_config.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/launch_url_in_web.dart';
import '../utils/misc/toast/toast.dart';
import '../utils/storage/dio_error_util.dart';
import 'async_buttons/async_text_button.dart';
import 'emoticons.dart';

class CommonErrorWidget extends HookConsumerWidget {
  const CommonErrorWidget({
    super.key,
    this.refresh,
    this.showGenericError = false,
    this.src,
    this.urlFetchInput,
    this.mangaId,
    required this.error,
  });
  final VoidCallback? refresh;
  final bool showGenericError;
  final Object error;
  final String? src;
  final UrlFetchInput? urlFetchInput;
  final String? mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final magic = ref.watch(getMagicProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final message = showGenericError
        ? context.l10n!.errorSomethingWentWrong
        : DioErrorUtil.localizeErrorMessage(error.toString(), context);
    final enableRefresh = useState(true);

    final mangaValue = mangaId != null
        ? ref.watch(mangaWithIdProvider(mangaId: mangaId ?? ""))
        : null;

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
          if (urlFetchInput != null) ...[
            AsyncTextButton(
              onPressed: () => launchUrlInWebView(
                context,
                ref,
                urlFetchInput!,
              ),
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
          if (magic.c5 && mangaId != null) ...[
            TextButton(
              onPressed: () {
                final manga = mangaValue?.valueOrNull;
                context.push(
                  Routes.globalSearch,
                  extra: GlobalSearchInput(
                    manga?.title ?? "",
                    manga: manga,
                  ),
                );
              },
              child: Column(
                children: [
                  Icon(Icomoon.exchange),
                  Text(context.l10n!.migrate_action_migrate),
                ],
              ),
            )
          ],
        ],
      ),
      footer: magic.c6 && mangaId != null
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 50),
              child: Text(
                context.l10n!.source_not_working_tips,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            )
          : null,
    );
  }
}
