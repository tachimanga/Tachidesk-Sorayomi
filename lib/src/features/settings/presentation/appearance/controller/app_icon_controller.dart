import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/device_providers.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../model/app_icon_model.dart';

part 'app_icon_controller.g.dart';

@riverpod
class AppIconKeyPref extends _$AppIconKeyPref
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: DBKeys.appIconKey.name,
        initial: DBKeys.appIconKey.initial,
      );
}

@riverpod
Future<Map<String, AppIconItem>> appIconMap(AppIconMapRef ref) async {
  Map<String, AppIconItem> result = {};
  final deviceInfo = ref.watch(deviceInfoProvider);
  final majorVersion = int.tryParse(deviceInfo.systemVersion.split('.').first) ?? 0;
  final supportAdaptiveIcon = majorVersion >= 18;
  //log("[ICON] osVersion=${deviceInfo.systemVersion}, supportAdaptiveIcon=$supportAdaptiveIcon");
  try {
    final jsonString = await rootBundle.loadString('assets/data/icons.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    final config = AppIconConfig.fromJson(jsonMap);
    for (final item in config.list) {
      if (item.adaptive == true && !supportAdaptiveIcon) {
        continue;
      }
      result[item.key] = item;
    }
  } catch (e) {
    log("parse json err $e");
  }
  return result;
}
