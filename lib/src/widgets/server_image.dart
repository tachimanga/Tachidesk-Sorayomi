// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/endpoints.dart';
import '../constants/enum.dart';
import '../constants/urls.dart';
import '../features/manga_book/domain/img/image_error_widget.dart';
import '../features/manga_book/domain/img/image_model.dart';
import '../features/manga_book/domain/img/unique_key_provider.dart';
import '../features/manga_book/presentation/reader/controller/reader_controller_v2.dart';
import '../features/settings/presentation/server/widget/credential_popup/credentials_popup.dart';
import '../features/settings/widgets/server_url_tile/server_url_tile.dart';
import '../global_providers/global_providers.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/launch_url_in_web.dart';
import '../utils/misc/toast/toast.dart';
import 'emoticons.dart';

class ServerImage extends ConsumerWidget {
  const ServerImage({
    super.key,
    required this.imageUrl,
    this.imageData,
    this.size,
    this.fit,
    this.appendApiToUrl = false,
    this.reloadButton = false,
    this.progressIndicatorBuilder,
    this.wrapper,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final ImgData? imageData;
  final Size? size;
  final BoxFit? fit;
  final bool appendApiToUrl;
  final bool reloadButton;
  final Widget Function(BuildContext, String, DownloadProgress)?
      progressIndicatorBuilder;
  final Widget Function(Widget child)? wrapper;

  /// Will resize the image in memory to have a certain width using [ResizeImage]
  final int? memCacheWidth;

  /// Will resize the image in memory to have a certain height using [ResizeImage]
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseUrl = ref.watch(serverUrlProvider);
    final authType = ref.watch(authTypeKeyProvider);
    final basicToken = ref.watch(credentialsProvider);
    final magic = ref.watch(getMagicProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final downscaleImage = ref.watch(downscaleImageProvider);

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
    // const userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36";
    // print("baseApi: " + baseApi);
    // CachedNetworkImage.logLevel = CacheManagerLogLevel.debug;

    final keyProvider = reloadButton ? uniqKeyProvider(baseApi) : null;
    Widget buildImgErrorWidget(ctx, url, error) {
      if (reloadButton) {
        return ImgError(
            text: error.toString(),
            button: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => ref.read(keyProvider!.notifier).reload(),
                  child: Text(context.l10n!.refresh),
                ),
                if (magic.b5) ...[
                  TextButton(
                    onPressed: () {
                      final url = userDefaults.getString("config.findAnswerUrl") ?? AppUrls.findAnswer.url;
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
            ));
      }
      return const Icon(
        Icons.broken_image_rounded,
        color: Colors.grey,
      );
    }
    return CachedNetworkImage(
      key: reloadButton ? ref.watch(keyProvider!) : null,
      imageUrl: baseApi,
      height: size?.height,
      httpHeaders: imageData?.headers ??
          (authType == AuthType.basic && basicToken != null
              ? {"Authorization": basicToken}
              : null),
      // ? {"Authorization": basicToken, "User-Agent": userAgent}
      // : {"User-Agent": userAgent},
      width: size?.width,
      fit: fit ?? BoxFit.cover,
      memCacheWidth: downscaleImage == true ? memCacheWidth : null,
      memCacheHeight: downscaleImage == true ? memCacheHeight : null,
      imageRenderMethodForWeb: authType == AuthType.basic && basicToken != null
          ? ImageRenderMethodForWeb.HttpGet
          : ImageRenderMethodForWeb.HtmlImage,
      progressIndicatorBuilder: progressIndicatorBuilder == null
          ? null
          : (context, url, progress) => wrapper != null
              ? wrapper!(progressIndicatorBuilder!(context, url, progress))
              : progressIndicatorBuilder!(context, url, progress),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      errorWidget: (context, url, error) => wrapper != null
          ? wrapper!(buildImgErrorWidget(context, url, error))
          : buildImgErrorWidget(context, url, error),
    );
  }
}

class ServerImageWithCpi extends StatelessWidget {
  const ServerImageWithCpi({
    super.key,
    required this.url,
    required this.outerSize,
    required this.innerSize,
    required this.isLoading,
  });
  final bool isLoading;
  final Size outerSize;
  final Size innerSize;
  final String url;
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
                )
              ],
            ),
          )
        : ServerImage(imageUrl: url, size: outerSize);
  }
}
