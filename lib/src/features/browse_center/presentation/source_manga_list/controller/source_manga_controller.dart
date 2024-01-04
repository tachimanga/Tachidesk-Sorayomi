// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/filter/filter_model.dart';
import '../../../domain/source/source_model.dart';

part 'source_manga_controller.g.dart';

@riverpod
FutureOr<Source?> source(SourceRef ref, String sourceId) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(sourceRepositoryProvider)
      .getSource(sourceId: sourceId, cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
class BaseSourceMangaFilterWithId extends _$BaseSourceMangaFilterWithId {

  @override
  Future<List<Filter>?> build(String sourceId) async {
    final result = await ref
        .watch(sourceRepositoryProvider)
        .getFilterList(sourceId: sourceId);
    ref.keepAlive();
    return result;
  }

  Future<List<Filter>?> reset() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => ref.watch(sourceRepositoryProvider).getFilterList(
              sourceId: sourceId,
              reset: true,
            ));
    state = result;
    return result.valueOrNull;
  }
}

@riverpod
class SourceMangaFilterList extends _$SourceMangaFilterList {

  @override
  AsyncValue<List<Filter>?> build(String sourceId) {
    final init = ref.watch(baseSourceMangaFilterWithIdProvider(sourceId));
    //log("[Filter]FilterList for $sourceId build, value: $init");
    log("[Filter]FilterList for $sourceId build");
    ref.onDispose(() {
      log("[Filter]FilterList for $sourceId dispose");
    });
    return init;
  }

  void updateFilter(List<Filter>? filter) =>
      state = state.copyWithData((p0) => filter);

  Future<List<Filter>?> reset() async {
    final provider = baseSourceMangaFilterWithIdProvider(sourceId);
    return await ref.read(provider.notifier).reset();
  }

  List<Map<String, dynamic>> get getAppliedFilter {
    final baseFilters = Filter.filtersToJson(
      ref.read(baseSourceMangaFilterWithIdProvider(sourceId)).valueOrNull ?? [],
    );
    final currentFilters = Filter.filtersToJson(state.valueOrNull ?? []);
    if (baseFilters.length != currentFilters.length) return currentFilters;
    const equality = DeepCollectionEquality();
    final filters = [
      for (int i = 0; i < baseFilters.length; i++)
        if (!equality.equals(currentFilters[i], baseFilters[i]))
          currentFilters[i],
    ];
    log("[Filter]getAppliedFilter $filters");
    return filters;
  }
}

@riverpod
class SourceDisplayMode extends _$SourceDisplayMode
    with SharedPreferenceEnumClientMixin<DisplayMode> {
  @override
  DisplayMode? build() => initialize(
        ref,
        key: DBKeys.sourceDisplayMode.name,
        initial: DBKeys.sourceDisplayMode.initial,
        enumList: DisplayMode.sourceDisplayList,
      );
}
