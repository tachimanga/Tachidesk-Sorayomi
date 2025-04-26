import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../browse_center/data/settings_repository/global_meta_repository.dart';
import '../../../../browse_center/domain/settings/global_meta_model.dart';
import '../../../domain/update/update_settings_model.dart';

part 'category_settings_controller.g.dart';

@riverpod
class DefaultCategoryPref extends _$DefaultCategoryPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.defaultCategory.initial,
        key: DBKeys.defaultCategory.name,
      );
}

@riverpod
class RemoteUpdateRestrictions extends _$RemoteUpdateRestrictions {
  @override
  Future<UpdateRestrictions?> build() async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await ref
        .read(globalMetaRepositoryProvider)
        .queryMeta(GlobalMetaKeys.updateRestrictions.key);
    return result?.updateRestrictions;
  }

  Future<void> upload(UpdateRestrictions value) async {
    await ref.read(globalMetaRepositoryProvider).updateMeta(
          GlobalMetaKeys.updateRestrictions.key,
          json.encode(value.toJson()),
        );
  }
}
