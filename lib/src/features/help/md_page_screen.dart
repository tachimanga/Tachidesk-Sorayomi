// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../routes/router_config.dart';
import '../../utils/event_util.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/launch_url_in_web.dart';
import '../../utils/misc/toast/toast.dart';
import 'domain/page_model.dart';
import 'page_builder.dart';

class MdPageScreen extends HookConsumerWidget {
  const MdPageScreen({
    super.key,
    required this.code,
  });

  final MdPageCode code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));

    final config = context.isDarkMode
        ? MarkdownConfig.darkConfig
        : MarkdownConfig.defaultConfig;

    final page = code.buildPage(context);

    useEffect(() {
      logEvent3("MD:PAGE:${code.name}");
      return;
    }, []);

    config.copy(
      configs: [
        LinkConfig(
          style: TextStyle(
            color: Color(0xff0969da),
            decoration: TextDecoration.underline,
          ),
          onTap: (url) {
            if (url.startsWith("/")) {
              context.push(url);
              return;
            }
            launchUrlInWeb(context, url, toast);
          },
        )
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(page.title),
      ),
      body: MarkdownWidget(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
        data: page.content,
        config: config,
      ),
    );
  }
}
