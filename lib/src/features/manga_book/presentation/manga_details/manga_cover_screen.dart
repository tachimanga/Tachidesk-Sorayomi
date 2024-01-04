// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../widgets/server_image.dart';
import '../../../settings/presentation/appearance/controller/theme_controller.dart';
import '../../../settings/presentation/share/controller/share_controller.dart';
import '../../../settings/widgets/server_url_tile/server_url_tile.dart';
import '../../domain/manga/manga_model.dart';
import '../reader/widgets/interactive_wrapper.dart';

class MangaCoverScreen extends ConsumerWidget {
  const MangaCoverScreen({
    super.key,
    required this.manga,
  });
  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final baseUrl = ref.watch(serverUrlProvider);
    final toast = ref.read(toastProvider(context));
    final watermarkSwitch = ref.watch(watermarkSwitchProvider);
    final appThemeData = ref.watch(themeSchemeColorProvider);

    final msgMap = <String, String>{
      "imageFileFetchFail": context.l10n!.imageFileFetchFail,
      "imageSaveSuccess": context.l10n!.imageSaveSuccess,
      "imageSaveFail": context.l10n!.imageSaveFail,
    };

    return Theme(
      data: appThemeData.dark.copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            systemOverlayStyle:
                SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          )),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              AsyncIconButton(
                onPressed: () async {
                  pipe.invokeMethod("LogEvent", "SHARE:SHARE_COVER");
                  (await AsyncValue.guard(() async {
                    FileInfo file = await getImageFile(baseUrl, msgMap);
                    await ref.read(shareActionProvider).shareImage(
                          file.file.path,
                          watermarkSwitch == true,
                          manga.title ?? "",
                          manga.realUrl ?? "",
                          msgMap,
                        );
                  }))
                      .showToastOnError(toast);
                },
                icon: const Icon(Icons.share_outlined),
              ),
              AsyncIconButton(
                onPressed: () async {
                  pipe.invokeMethod("LogEvent", "SHARE:SAVE_COVER");
                  (await AsyncValue.guard(() async {
                    FileInfo file = await getImageFile(baseUrl, msgMap);
                    await ref.read(shareActionProvider).saveImage(
                        file.file.path, watermarkSwitch == true, msgMap);
                    toast.show(msgMap["imageSaveSuccess"]!,
                        gravity: ToastGravity.CENTER);
                  }))
                      .showToastOnError(toast);
                },
                icon: const Icon(Icons.save_outlined),
              ),
              // IconButton(
              //   onPressed: () {},
              //   icon: const Icon(Icons.edit_outlined),
              // ),
            ],
          ),
          body: InteractiveWrapper(
            child: ServerImage(
              fit: BoxFit.contain,
              size: Size.fromHeight(context.height),
              imageUrl: manga.thumbnailUrl ?? "",
              imageData: manga.thumbnailImg,
            ),
          ),
        ),
      ),
    );
  }

  Future<FileInfo> getImageFile(
      String? baseUrl, Map<String, String> msgMap) async {
    final key = buildImageUrl(
        imageUrl: manga.thumbnailUrl ?? "",
        imageData: manga.thumbnailImg,
        baseUrl: baseUrl);
    log("get file url:$key");
    final file = await DefaultCacheManager().getFileFromCache(key);
    log("save file path:${file?.file.path}");
    if (file == null) {
      throw msgMap["imageFileFetchFail"]!;
    }
    return file;
  }
}
