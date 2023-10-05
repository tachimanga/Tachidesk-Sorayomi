

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../constants/gen/assets.gen.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../data/settings_repository/settings_repository.dart';
import 'webview_provider.dart';


class WebViewScreen extends HookConsumerWidget {
  const WebViewScreen({
    super.key,
    required this.url,
  });

  final String? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundColor = context.isDarkMode ? Colors.black : Colors.white;
    final controller = ref.watch(webViewControllerProvider(url: url ?? "", backgroundColor: backgroundColor));
    final uploadCookiesOnDispose = ref.watch(uploadCookiesOnDisposeProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.browse),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}