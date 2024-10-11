// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../constants/db_keys.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/cover/cover_cache_manager.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/log.dart';
import '../../../../utils/manga_cover_util.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../../widgets/server_image.dart';
import '../../../../widgets/text_premium.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../../settings/presentation/appearance/controller/theme_controller.dart';
import '../../../settings/presentation/share/controller/share_controller.dart';
import '../../../settings/widgets/server_url_tile/server_url_tile.dart';
import '../../domain/manga/manga_model.dart';
import '../reader/widgets/interactive_wrapper.dart';
import 'controller/manga_cover_controller.dart';
import 'controller/manga_details_controller.dart';

class MangaCoverScreen extends HookConsumerWidget {
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
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final customCoverExistProvider =
        mangaCustomCoverExistProvider(mangaId: "${manga.id}");
    final customCoverExist = ref.watch(customCoverExistProvider);

    final msgMap = <String, String>{
      "imageFileFetchFail": context.l10n!.imageFileFetchFail,
      "imageSaveSuccess": context.l10n!.imageSaveSuccess,
      "imageSaveFail": context.l10n!.imageSaveFail,
      "save_image_user_denied_msg": context.l10n!.save_image_user_denied_msg,
    };

    final keyState = useState(UniqueKey());

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

    refreshCover() {
      if (context.mounted) {
        toast.show(context.l10n!.cover_updated,
            toastDuration: const Duration(seconds: 3));
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      keyState.value = UniqueKey();
      ref.invalidate(customCoverExistProvider);
      ref.read(mangaWithIdProvider(mangaId: "${manga.id}").notifier).refresh();
    }

    onEdit() async {
      logEvent3("COVER:EDIT_COVER");
      final maxWidth = max(context.width, context.height) * 0.8;
      final maxWidthPx = (maxWidth * context.devicePixelRatio).toInt() * 1.0;

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        requestFullMetadata: false,
        maxHeight: maxWidthPx,
        maxWidth: maxWidthPx,
      );
      if (pickedFile != null) {
        (await AsyncValue.guard(() async {
          CoverCacheManager().saveCustomCover("${manga.id}", pickedFile.path);
        }))
            .showToastOnError(toast);
        refreshCover();
      }
    }

    onDelete() async {
      (await AsyncValue.guard(() async {
        CoverCacheManager().deleteCustomCover("${manga.id}");
      }))
          .showToastOnError(toast);
      refreshCover();
    }

    EdgeInsets windowPadding = MediaQuery.paddingOf(context);

    showCustomCoverOption() async {
      showModalBottomSheet(
        context: context,
        backgroundColor: context.theme.cardColor,
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: windowPadding.bottom),
          child: CustomCoverActionWidget(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

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
                mangaId: "${manga.id}",
                onEdit: onEdit,
                onSave: onSave,
                onShare: onShare,
                showCustomCoverOption: showCustomCoverOption,
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
              customCoverExist.valueOrNull != true
                  ? IconButton(
                      onPressed: () {
                        if (!purchaseGate && !testflightFlag) {
                          logEvent3("COVER:EDIT_COVER:GATE1");
                          context.push(Routes.purchase);
                          return;
                        }
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined),
                    )
                  : PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: KBorderRadius.r16.radius,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: onEdit,
                          child: Text(context.l10n!.edit),
                        ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: Text(context.l10n!.delete),
                        ),
                      ],
                    ),
            ],
          ),
          body: InteractiveWrapper(
            child: ServerImage(
              key: keyState.value,
              fit: BoxFit.contain,
              size: Size.fromHeight(context.height),
              imageUrl: manga.thumbnailUrl ?? "",
              imageData: manga.thumbnailImg,
              extInfo: CoverExtInfo.build(manga),
            ),
          ),
        ),
      ),
    );
  }

  Future<FileInfo> getImageFile(
      String? baseUrl, Map<String, String> msgMap) async {
    final url = buildImageUrl(
        imageUrl: manga.thumbnailUrl ?? "",
        imageData: manga.thumbnailImg,
        baseUrl: DBKeys.serverUrl.initial);
    try {
      final file = await CoverCacheManager()
          .getFileStream(
            url,
            headers: manga.thumbnailImg?.headers,
            extInfo: CoverExtInfo.build(manga),
          )
          .firstWhere((r) => r is FileInfo);
      return file as FileInfo;
    } catch (e) {
      throw msgMap["imageFileFetchFail"]!;
    }
  }
}

class CoverActionWidget extends HookConsumerWidget {
  const CoverActionWidget({
    super.key,
    required this.mangaId,
    required this.onEdit,
    required this.onSave,
    required this.onShare,
    required this.showCustomCoverOption,
  });

  final String mangaId;
  final AsyncCallback onEdit;
  final AsyncCallback onSave;
  final AsyncCallback onShare;
  final AsyncCallback showCustomCoverOption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final watermarkSwitch = ref.watch(watermarkSwitchProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final premiumFlag = purchaseGate || testflightFlag;
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
          leading: const Icon(Icons.edit_outlined),
          title: premiumFlag
              ? Text(context.l10n!.edit_cover)
              : TextPremium(text: context.l10n!.edit_cover),
          onTap: () async {
            if (!premiumFlag) {
              logEvent3("COVER:EDIT_COVER:GATE2");
              context.push(Routes.purchase);
              return;
            }
            context.pop();
            final cover = await CoverCacheManager().getCustomCover(mangaId);
            if (cover == null) {
              onEdit();
            } else {
              showCustomCoverOption();
            }
          },
        ),
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

class CustomCoverActionWidget extends HookConsumerWidget {
  const CustomCoverActionWidget({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncCallback onEdit;
  final AsyncCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(context.l10n!.edit),
          onTap: () {
            context.pop();
            onEdit();
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(context.l10n!.delete),
          onTap: () {
            context.pop();
            onDelete();
          },
        ),
      ],
    );
  }
}
