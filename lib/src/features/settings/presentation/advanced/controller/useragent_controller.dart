import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/device_providers.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'useragent_controller.g.dart';

@riverpod
class UserAgentTypePref extends _$UserAgentTypePref
    with SharedPreferenceEnumClientMixin<UserAgentTypeEnum> {
  @override
  UserAgentTypeEnum? build() => initialize(
        ref,
        initial: DBKeys.userAgentType.initial,
        key: DBKeys.userAgentType.name,
        enumList: UserAgentTypeEnum.values,
      );
}

@riverpod
Future<Map<int, String>?> userAgentStrings(Ref ref) async {
  final pipe = ref.watch(getMagicPipeProvider);
  return await pipe.invokeMapMethod<int, String>("USERAGENT:FETCH");
}
