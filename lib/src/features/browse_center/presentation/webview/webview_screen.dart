import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http_status/http_status.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/popup_Item_with_icon_child.dart';
import '../../data/settings_repository/settings_repository.dart';
import '../../domain/browse/browse_model.dart';

class WebViewScreen extends HookConsumerWidget {
  const WebViewScreen({
    super.key,
    required this.params,
  });

  final UrlFetchOutput? params;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final backgroundColor = context.isDarkMode ? Colors.black : Colors.white;
    final url = params?.url;

    useEffect(() {
      toast.show("Loading...",
          gravity: ToastGravity.CENTER, withMicrotask: true);
      return () {
        toast.close(withMicrotask: true);
      };
    }, []);

    final loadingState = useState(false);

    final controller = useMemoized(() {
      log("webViewController $params");
      if (url == null) {
        return null;
      }
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(backgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
              //debugPrint('WebView is loading (progress : $progress%)');
              if (!context.mounted) {
                return;
              }
              loadingState.value = progress < 99;
            },
            onPageStarted: (String url) {
              //debugPrint('Page started loading: $url');
              if (!context.mounted) {
                return;
              }
              loadingState.value = true;
            },
            onPageFinished: (String url) {
              //debugPrint('Page finished loading: $url');
              if (!context.mounted) {
                return;
              }
              loadingState.value = false;
            },
            onWebResourceError: (WebResourceError error) {
              log("[flutter_webview] onWebResourceError $error");
              if (!context.mounted) {
                return;
              }
              toast.showError(error.description);
            },
            onHttpError: (HttpResponseError error) {
              log("[flutter_webview] onHttpError ${error.response?.statusCode}");
              if (!context.mounted) {
                return;
              }
              if (error.response?.statusCode != 403) {
                toast.showError(_buildHttpErrorMessage(context, error));
              }
            },
          ),
        );
      if (params?.userAgent != null) {
        controller.setUserAgent(params?.userAgent);
      }
      controller.loadRequest(Uri.parse(url));
      return controller;
    });

    final pipe = ref.watch(getMagicPipeProvider);
    useRouteObserver(routeObserver, didPop: () async {
      log("WebViewScreen did pop");
      final json = await pipe.invokeMethod("GetCookies");
      log("GetCookies $json");
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loadingState.value) ...[
                  MiniCircularProgressIndicator(
                    color: context.iconColor,
                  )
                ],
                Text(
                  context.l10n!.browse,
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
            if (url?.isNotEmpty == true) ...[
              Text(
                url ?? "",
                style:
                    context.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
        titleSpacing: 0,
        actions: [
          IconButton(
            onPressed: () => launchUrlInSafari(context, url ?? "", toast),
            icon: const Icon(Icons.public),
          ),
          PopupMenuButton(
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.r16.radius,
            ),
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => launchUrlInSafari(context, url ?? "", toast),
                child: PopupItemWithIconChild(
                  icon: const Icon(Icons.public),
                  label: Text(context.l10n!.open_in_safari),
                ),
              ),
              PopupMenuItem(
                onTap: () async {
                  toast.show("${context.l10n!.clearCookies}...",
                      gravity: ToastGravity.CENTER,
                      toastDuration: const Duration(seconds: 3));
                  try {
                    await pipe.invokeMethod("ClearCookies");
                    log("clearCookies succ");
                  } catch (e) {
                    log("clearCookies err $e");
                  }
                  toast.close();
                  if (context.mounted) {
                    toast.show(context.l10n!.cookiesCleared,
                        gravity: ToastGravity.CENTER);
                  }
                },
                child: PopupItemWithIconChild(
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: Text(context.l10n!.clearCookies),
                ),
              ),
            ],
          ),
        ],
      ),
      body: controller != null
          ? WebViewWidget(controller: controller)
          : const Text("Url not valid"),
    );
  }

  String _buildHttpErrorMessage(BuildContext context, HttpResponseError error) {
    var message = "${error.response?.statusCode} ERROR";
    try {
      final s = HttpStatus.fromCode(error.response?.statusCode ?? -1);
      message = "${s.code} ${s.name}";
    } catch (_) {}
    return context.l10n!.errorMessageFrom(message);
  }
}
