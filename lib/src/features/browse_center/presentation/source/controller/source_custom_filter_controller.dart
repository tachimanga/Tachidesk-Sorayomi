// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../settings/domain/repo/repo_model.dart';
import '../../../data/source_repository/source_repository.dart';
import '../domain/source_meta_model.dart';

part 'source_custom_filter_controller.g.dart';

const kCustomFiltersKey = "filters";

@riverpod
Future<SourceMeta?> sourceMeta(Ref ref, String sourceId, String key) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(sourceRepositoryProvider)
      .queryMeta(sourceId: sourceId, key: key, cancelToken: token);
  return result;
}

@riverpod
class SourceCustomFiltersWithSourceId
    extends _$SourceCustomFiltersWithSourceId {
  Timer? debounce;
  bool? loaded;

  @override
  List<SourceCustomFilter>? build({required String sourceId}) {
    final value = ref.watch(sourceMetaProvider(sourceId, kCustomFiltersKey));
    final meta = value.valueOrNull;
    SourceCustomFilterConfig? config;
    if (meta?.value?.isNotEmpty == true) {
      try {
        config = SourceCustomFilterConfig.fromJson(json.decode(meta!.value!));
      } catch (e) {
        log("[Filters]SourceCustomFilterConfig parse error:$e");
      }
    }
    loaded = meta != null;
    log("[Filters]load custom filter $meta");
    return config?.filters;
  }

  void insert(SourceCustomFilter filter) {
    log("[Filters]insert $filter");
    if (loaded != true) {
      log("filters not loaded");
      return;
    }
    state = [filter, ...?state];
    commit();
  }

  void remove(SourceCustomFilter filter) {
    log("[Filters]remove $filter");
    if (loaded != true) {
      log("filters not loaded");
      return;
    }
    state = state?.where((item) => item != filter).toList();
    commit();
  }

  void commit() {
    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          await ref.read(sourceRepositoryProvider).updateMeta(
                sourceId: sourceId,
                key: kCustomFiltersKey,
                value: jsonEncode(
                    SourceCustomFilterConfig(filters: state).toJson()),
              );
        });
      },
    );
  }
}
