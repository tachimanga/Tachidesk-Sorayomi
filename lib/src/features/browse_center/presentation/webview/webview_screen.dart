import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../constants/gen/assets.gen.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
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
    final toast = ref.read(toastProvider(context));
    final backgroundColor = context.isDarkMode ? Colors.black : Colors.white;

    useEffect(() {
      toast.show("Loading...", gravity: ToastGravity.CENTER, withMicrotask: true);
      return () {
        toast.close(withMicrotask: true);
      };
    }, []);

    final controller = useMemoized(() {
      if (url == null) {
        return null;
      }
      print("webViewController $url");
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(backgroundColor)
        // ..setUserAgent("Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/115.0.5790.160 Mobile/15E148 Safari/604.1")
        ..loadRequest(Uri.parse(url!));
      return controller;
    });

    final pipe = ref.watch(getMagicPipeProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    useRouteObserver(routeObserver, didPop: () async {
      log("WebViewScreen did pop");
      final json = await pipe.invokeMethod("GetCookies");
      log("GetCookies $json");
      try {
        final result = await settingsRepository.uploadSettings(json: json);
        log("uploadCookies succ");
      } catch (e) {
        log("uploadCookies err $e");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.browse),
        actions: [
          IconButton(
            onPressed: () => launchUrlInWeb(context, url ?? "", toast),
            icon: const Icon(Icons.public),
          ),
        ],
      ),
      body: controller != null
          ? WebViewWidget(controller: controller)
          : const Text("Url not valid"),
    );
  }
}
