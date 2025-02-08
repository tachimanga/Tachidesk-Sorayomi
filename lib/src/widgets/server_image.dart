// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:octo_image/octo_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../constants/endpoints.dart';
import '../constants/enum.dart';
import '../constants/urls.dart';
import '../features/manga_book/domain/img/image_error_widget.dart';
import '../features/manga_book/domain/img/image_model.dart';
import '../features/manga_book/domain/img/unique_key_provider.dart';
import '../features/manga_book/presentation/reader/controller/reader_controller_v2.dart';
import '../features/settings/widgets/server_url_tile/server_url_tile.dart';
import '../global_providers/global_providers.dart';
import '../routes/router_config.dart';
import '../utils/classes/trace/trace_model.dart';
import '../utils/cover/cover_cache_manager.dart';
import '../utils/event_util.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/image_util.dart';
import '../utils/launch_url_in_web.dart';
import '../utils/log.dart';
import '../utils/manga_cover_util.dart';
import '../utils/misc/toast/toast.dart';
import 'emoticons.dart';
import 'package:shared_preferences/shared_preferences.dart';

final codecMessages = <String>[
  "Exception: Codec failed to produce an image, possibly due to invalid image data.",
  "Exception: Invalid image data",
];

class ServerImage extends HookConsumerWidget {
  const ServerImage({
    super.key,
    required this.imageUrl,
    this.imageData,
    this.size,
    this.fit,
    this.alignment = Alignment.center,
    this.appendApiToUrl = false,
    this.reloadButton = false,
    this.progressIndicatorBuilder,
    this.wrapper,
    this.imageSizeCache,
    this.decodeWidth,
    this.decodeHeight,
    this.maxDecodeWidth,
    this.maxDecodeHeight,
    this.traceInfo,
    this.chapterUrl,
    this.extInfo,
    this.imageBuilder,
  });

  final String imageUrl;
  final ImgData? imageData;
  final Size? size;
  final BoxFit? fit;
  final Alignment alignment;
  final bool appendApiToUrl;
  final bool reloadButton;
  final Widget Function(BuildContext, String, DownloadProgress)?
      progressIndicatorBuilder;
  final Widget Function(Widget child)? wrapper;
  final ImageSizeCache? imageSizeCache;

  /// Will resize the image in memory to have a certain width using [ResizeImage]
  final int? decodeWidth;

  /// Will resize the image in memory to have a certain height using [ResizeImage]
  final int? decodeHeight;

  /// decode pixels limit
  final double? maxDecodeWidth;
  final double? maxDecodeHeight;

  // extra fields
  final TraceInfo? traceInfo;
  final String? chapterUrl;
  final Map<String, String>? extInfo;

  // image builder
  final ImageWidgetBuilder? imageBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(serverUrlProvider);
    final downscaleImage = ref.watch(downscaleImageProvider);
    final downscalePageImage = ref.watch(downscalePageProvider);

    var baseApi =
        "${Endpoints.baseApi(baseUrl: baseUrl, appendApiToUrl: appendApiToUrl)}"
        "$imageUrl";
    if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
      baseApi = imageUrl;
    }
    //print("imageData $imageData");
    if (imageData?.url != null) {
      baseApi = imageData!.url!;
    }
    // CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

    final keyState = useState(UniqueKey());

    final memCacheWidth = decodeWidth != null && downscaleImage == true
        ? (decodeWidth! * context.devicePixelRatio).toInt()
        : null;
    final memCacheHeight = decodeHeight != null && downscaleImage == true
        ? (decodeHeight! * context.devicePixelRatio).toInt()
        : null;

    bool enableMaxDecode = downscalePageImage == true &&
        (decodeWidth == null && decodeHeight == null);
    final maxDecodePixelWidth = maxDecodeWidth != null && enableMaxDecode
        ? (maxDecodeWidth! * context.devicePixelRatio).toInt()
        : null;
    final maxDecodePixelHeight = maxDecodeHeight != null && enableMaxDecode
        ? (maxDecodeHeight! * context.devicePixelRatio).toInt()
        : null;

    return CachedNetworkImage(
      key: keyState.value,
      imageUrl: baseApi,
      height: size?.height,
      httpHeaders: imageData?.headers,
      width: size?.width,
      fit: fit ?? BoxFit.cover,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      progressIndicatorBuilder: progressIndicatorBuilder == null
          ? null
          : (context, url, progress) => wrapper != null
              ? wrapper!(progressIndicatorBuilder!(context, url, progress))
              : progressIndicatorBuilder!(context, url, progress),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      errorWidget: (ctx, url, error) => wrapper != null
          ? wrapper!(buildErrorWidget(context, ref, keyState, error, baseApi))
          : buildErrorWidget(context, ref, keyState, error, baseApi),
      imageSizeCache: imageSizeCache,
      cacheManager: buildCacheManager(extInfo),
      extInfo: extInfo,
      maxDecodePixelWidth: maxDecodePixelWidth,
      maxDecodePixelHeight: maxDecodePixelHeight,
      imageBuilder: imageBuilder,
    );
  }

  Widget buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<UniqueKey> keyState,
    dynamic error,
    String baseApi,
  ) {
    if (!reloadButton) {
      return const Icon(
        Icons.broken_image_rounded,
        color: Colors.grey,
      );
    }

    final magic = ref.read(getMagicProvider);
    final userDefaults = ref.read(sharedPreferencesProvider);
    if (codecMessages.contains(error.toString())) {
      return ImgError(
        text: error.toString(),
        traceInfo: traceInfo,
        imageUrl: baseApi,
        button: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () async {
                await onTapOpenButton(
                  baseApi,
                  traceInfo,
                  error.toString(),
                );
              },
              child: Text(context.l10n!.tap_to_open),
            ),
          ],
        ),
      );
    }
    return ImgError(
      text: error.toString(),
      traceInfo: traceInfo,
      imageUrl: baseApi,
      button: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => keyState.value = (UniqueKey()),
            child: Text(context.l10n!.refresh),
          ),
          if (chapterUrl?.isNotEmpty == true) ...[
            TextButton(
              onPressed: () {
                onTapWebViewButton(
                  context,
                  chapterUrl,
                  traceInfo,
                  error.toString(),
                );
              },
              child: Text(context.l10n!.webView),
            ),
          ],
          if (magic.b5) ...[
            TextButton(
              onPressed: () {
                final url = userDefaults.getString("config.findAnswerUrl") ??
                    AppUrls.findAnswer.url;
                launchUrlInWeb(
                  context,
                  "$url?src=img&err=${error.toString()}",
                  ref.read(toastProvider(context)),
                );
              },
              child: Text(context.l10n!.help),
            )
          ],
        ],
      ),
    );
  }

  Future<void> onTapOpenButton(
    String imageUrl,
    TraceInfo? traceInfo,
    String? error,
  ) async {
    final file = await DefaultCacheManager().getFileFromCache(imageUrl);
    final path = file?.file.path;
    final exist = path?.isNotEmpty == true;
    log("img file path:$path");

    logEvent3("READER:IMAGE:OPEN:PREVIEW", {
      "type": traceInfo?.type,
      "sourceId": traceInfo?.sourceId,
      "x": traceInfo?.mangaUrl,
      "url": imageUrl,
      "error": "$error, e:$exist",
    });

    if (exist) {
      await pipe.invokeMethod("READER:IMAGE:PREVIEW", {"path": path});
    }
  }

  void onTapWebViewButton(
    BuildContext context,
    String? chapterUrl,
    TraceInfo? traceInfo,
    String? error,
  ) {
    final parts = error?.split(", uri = ");
    logEvent3("READER:IMAGE:OPEN:WEBVIEW", {
      "type": traceInfo?.type,
      "sourceId": traceInfo?.sourceId,
      "x": traceInfo?.mangaUrl,
      "url": imageUrl,
      "error": parts.firstOrNull,
    });
    context.push(Routes.getWebView(chapterUrl ?? ""));
  }
}

class ServerImageWithCpi extends StatelessWidget {
  const ServerImageWithCpi({
    super.key,
    required this.url,
    required this.outerSize,
    required this.innerSize,
    required this.isLoading,
    this.decodeWidth,
    this.decodeHeight,
  });
  final bool isLoading;
  final Size outerSize;
  final Size innerSize;
  final String url;
  final int? decodeWidth;
  final int? decodeHeight;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SizedBox.fromSize(
            size: outerSize,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                ServerImage(
                  imageUrl: url,
                  size: innerSize,
                  decodeWidth: decodeWidth,
                  decodeHeight: decodeHeight,
                )
              ],
            ),
          )
        : ServerImage(
            imageUrl: url,
            size: outerSize,
            decodeWidth: decodeWidth,
            decodeHeight: decodeHeight,
          );
  }
}

CacheManager? buildCacheManager(Map<String, String>? extInfo) {
  if (CoverExtInfo.fetchMangaId(extInfo) != null) {
    return CoverCacheManager();
  }
  return null;
}

ImageProvider buildCachedNetworkImageProvider({
  required String? baseUrl,
  required String imageUrl,
  ImgData? imageData,
  Map<String, String>? extInfo,
}) {
  final url = buildImageUrl(
    baseUrl: baseUrl,
    imageUrl: imageUrl,
    imageData: imageData,
  );
  return CachedNetworkImageProvider(
    url,
    headers: imageData?.headers,
    cacheManager: buildCacheManager(extInfo),
    extInfo: extInfo,
  );
}
