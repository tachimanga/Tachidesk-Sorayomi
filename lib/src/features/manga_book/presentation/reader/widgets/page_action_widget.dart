// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/image_util.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/premium_required_tile.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../settings/presentation/share/controller/share_controller.dart';
import '../../../../settings/widgets/server_url_tile/server_url_tile.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/img/image_model.dart';
import '../../../domain/manga/manga_model.dart';

class PageActionWidget extends HookConsumerWidget {
  const PageActionWidget({
    super.key,
    required this.manga,
    required this.chapter,
    required this.imageUrl,
    this.imageData,
  });

  final Manga manga;
  final Chapter chapter;
  final String imageUrl;
  final ImgData? imageData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final baseUrl = ref.watch(serverUrlProvider);
    final toast = ref.read(toastProvider(context));
    final watermarkSwitch = ref.watch(watermarkSwitchProvider);

    final msgMap = <String, String>{
      "imageFileFetchFail": context.l10n!.imageFileFetchFail,
      "imageSaveSuccess": context.l10n!.imageSaveSuccess,
      "imageSaveFail": context.l10n!.imageSaveFail,
    };

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
          pipe.invokeMethod("LogEvent", "READER:WATERMARK:SAVE:PAGE:GATE");
          fakeWatermarkSwitch.value = false;
        } else {
          ref.read(watermarkSwitchProvider.notifier).update(false);
          pipe.invokeMethod("LogEvent", "READER:WATERMARK:SAVE:PAGE:OFF");
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
            pipe.invokeMethod("LogEvent", "SHARE:SAVE_PAGE");
            (await AsyncValue.guard(() async {
              FileInfo file = await getImageFile(baseUrl, msgMap);
              await ref
                  .read(shareActionProvider)
                  .saveImage(file.file.path, watermarkSwitch == true, msgMap);
              toast.show(msgMap["imageSaveSuccess"]!,
                  gravity: ToastGravity.CENTER);
            }))
                .showToastOnError(toast);
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
            final text = context.l10n!.chapterShareText(manga.author ?? "",
                chapter.name ?? "", chapter.realUrl ?? "", manga.title ?? "");
            pipe.invokeMethod("LogEvent", "SHARE:SHARE_PAGE");
            (await AsyncValue.guard(() async {
              FileInfo file = await getImageFile(baseUrl, msgMap);
              await ref.read(shareActionProvider).shareImage(
                    file.file.path,
                    watermarkSwitch == true,
                    text,
                    "",
                    msgMap,
                  );
            }))
                .showToastOnError(toast);
          },
        ),
      ],
    );
  }

  Future<FileInfo> getImageFile(
      String? baseUrl, Map<String, String> msgMap) async {
    final key = buildImageUrl(
        imageUrl: imageUrl,
        imageData: imageData,
        baseUrl: baseUrl,
        appendApiToUrl: true);
    log("get file url:$key");
    final file = await DefaultCacheManager().getFileFromCache(key);
    log("file path:${file?.file.path}");
    if (file == null) {
      throw msgMap["imageFileFetchFail"]!;
    }
    return file;
  }
}
