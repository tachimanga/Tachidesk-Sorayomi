// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../../../widgets/premium_required_tile.dart';
import '../../../../widgets/server_image.dart';
import '../../../custom/inapp/purchase_providers.dart';
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

    onShare() async {
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
    }

    onSave() async {
      pipe.invokeMethod("LogEvent", "SHARE:SAVE_COVER");
      (await AsyncValue.guard(() async {
        FileInfo file = await getImageFile(baseUrl, msgMap);
        await ref
            .read(shareActionProvider)
            .saveImage(file.file.path, watermarkSwitch == true, msgMap);
        toast.show(msgMap["imageSaveSuccess"]!, gravity: ToastGravity.CENTER);
      }))
          .showToastOnError(toast);
    }

    EdgeInsets windowPadding = MediaQuery.paddingOf(context);
    return Theme(
      data: appThemeData.dark.copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            systemOverlayStyle:
                SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
          )),
      child: GestureDetector(
        onTap: () => context.pop(),
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: context.theme.cardColor,
            builder: (context) => Padding(
              padding: EdgeInsets.only(bottom: windowPadding.bottom),
              child: CoverActionWidget(
                onSave: onSave,
                onShare: onShare,
              ),
            ),
          );
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            actions: [
              AsyncIconButton(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
              ),
              AsyncIconButton(
                onPressed: onSave,
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

class CoverActionWidget extends HookConsumerWidget {
  const CoverActionWidget({
    super.key,
    required this.onSave,
    required this.onShare,
  });

  final AsyncCallback onSave;
  final AsyncCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final watermarkSwitch = ref.watch(watermarkSwitchProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final fakeWatermarkSwitch = useState(true);

    final watermarkChip = InputChip(
      label: Text(
        context.l10n!.label_watermark,
        style: fakeWatermarkSwitch.value
            ? context.textTheme.labelMedium
            : context.textTheme.labelMedium?.copyWith(
                decoration: TextDecoration.lineThrough, color: Colors.grey),
      ),
      onDeleted: () {
        if (!purchaseGate && !testflightFlag) {
          pipe.invokeMethod("LogEvent", "READER:WATERMARK:SAVE:COVER:GATE");
          fakeWatermarkSwitch.value = false;
        } else {
          ref.read(watermarkSwitchProvider.notifier).update(false);
          pipe.invokeMethod("LogEvent", "READER:WATERMARK:SAVE:COVER:OFF");
        }
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.save_outlined),
          title: Text(context.l10n!.save),
          trailing: watermarkSwitch == true ? watermarkChip : null,
          onTap: () async {
            context.pop();
            onSave();
          },
        ),
        if (!fakeWatermarkSwitch.value) ...[
          const PremiumRequiredTile(),
        ],
        ListTile(
          leading: const Icon(
            Icons.share_outlined,
          ),
          title: Text(context.l10n!.share),
          onTap: () async {
            context.pop();
            onShare();
          },
        ),
      ],
    );
  }
}
