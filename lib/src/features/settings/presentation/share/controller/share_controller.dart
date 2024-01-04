import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../data/backup/backup_repository.dart';
import '../../../domain/backup/backup_model.dart';

part 'share_controller.g.dart';

class ShareAction {
  const ShareAction(this.pipe);
  final MethodChannel pipe;

  String convertMessage(Map<String, String> msgMap, String? message) {
    final map = {
      "IMAGE_FORMAT_NOT_SUPPORT": "imageSaveFail",
    };
    final code = map[message];
    if (code != null) {
      return "${msgMap[code]}($message)";
    }
    return message ?? "";
  }

  Future<void> saveImage(
      String path, bool watermark, Map<String, String> msgMap) async {
    final str = await pipe.invokeMethod(
        "SHARE:SAVE_IMAGE", {"path": path, "watermark": watermark});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertMessage(msgMap, result.message));
    }
  }

  Future<void> shareImage(String path, bool watermark, String text, String link,
      Map<String, String> msgMap) async {
    final str = await pipe.invokeMethod("SHARE:SHARE_IMAGE",
        {"path": path, "watermark": watermark, "text": text, "link": link});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertMessage(msgMap, result.message));
    }
  }

  Future<void> shareText(String text, {String link = ""}) async {
    final str = await pipe
        .invokeMethod("SHARE:SHARE_TEXT", {"text": text, "link": link});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(result.message);
    }
  }
}

@riverpod
ShareAction shareAction(ShareActionRef ref) =>
    ShareAction(ref.watch(getMagicPipeProvider));

@riverpod
class WatermarkSwitch extends _$WatermarkSwitch
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.watermarkSwitch.name,
        initial: DBKeys.watermarkSwitch.initial,
      );
}
