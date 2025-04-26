// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/filter/filter_model.dart';
import '../../../domain/filter_state/filter_state_model.dart';
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
class SourceMangaFilterList extends _$SourceMangaFilterList {
  List<Filter>? remoteFilters;

  @override
  AsyncValue<List<Filter>?> build(String sourceId) {
    log("[Filters]SourceMangaFilterList for $sourceId build");
    ref.onDispose(() {
      log("[Filters]SourceMangaFilterList for $sourceId dispose");
    });
    return AsyncData(null);
  }

  Future<List<Filter>?> loadAndReset() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
        () => ref.watch(sourceRepositoryProvider).getFilterList(
              sourceId: sourceId,
              reset: true,
            ));
    state = result;
    remoteFilters = result.valueOrNull;
    return remoteFilters;
  }

  void updateFilter(List<Filter>? filter) =>
      state = state.copyWithData((p0) => filter);

  List<Map<String, dynamic>> get getAppliedFilter {
    final baseFilters = Filter.filtersToJson(
      remoteFilters ?? [],
    );
    final currentFilters = Filter.filtersToJson(state.valueOrNull ?? []);
    if (baseFilters.length != currentFilters.length) return currentFilters;
    const equality = DeepCollectionEquality();
    final filters = [
      for (int i = 0; i < baseFilters.length; i++)
        if (!equality.equals(currentFilters[i], baseFilters[i]))
          currentFilters[i],
    ];
    log("[Filters]getAppliedFilter $filters");
    return filters;
  }

  bool applyChangeToFilter(List<Map<String, dynamic>>? filters) {
    log("[Filters]applyFilter $filters");
    final changes = filters
        ?.map((f) => FilterChange.fromJson(f))
        .where((change) => change.position != null && change.state != null)
        .toList();
    if (changes == null) {
      log("[Filters]changes is null");
      return false;
    }
    if (remoteFilters == null) {
      log("[Filters]remoteFilters is null");
      return false;
    }
    var newFilters = [...?remoteFilters];
    var success = false;
    for (final change in changes) {
      final index = change.position!;
      if (index < newFilters.length) {
        final filter = newFilters[index];
        final newFilterState =
            _applyChangeToFilterState(filter.filterState, change);
        if (newFilterState != null) {
          success = true;
          final newFilter = filter.copyWith(filterState: newFilterState);
          newFilters = ([...newFilters]..replaceRange(
              index,
              index + 1,
              [newFilter],
            ));
        }
      }
    }
    if (success) {
      updateFilter(newFilters);
    }
    return success;
  }

  FilterState? _applyChangeToFilterState(
      FilterState? filterState, FilterChange change) {
    final newFilterState = filterState?.mapOrNull(text: (text) {
      return text.copyWith(state: change.state);
    }, checkBox: (checkBox) {
      return checkBox.copyWith(state: change.state == "true");
    }, triState: (triState) {
      return triState.copyWith(state: int.tryParse(change.state!));
    }, sort: (sort) {
      return sort.copyWith(
          state: SortState.fromJson(jsonDecode(change.state!)));
    }, select: (select) {
      return select.copyWith(state: int.tryParse(change.state!));
    }, group: (group) {
      final groupChange = _buildGroupChange(change.state!);
      if (groupChange == null) {
        return null;
      }
      final groupIndex = groupChange.position!;
      if (groupIndex < group.state!.length) {
        final groupFilter = group.state![groupIndex];
        final newGroupFilterState =
            _applyChangeToFilterState(groupFilter.filterState, groupChange);
        if (newGroupFilterState != null) {
          final newGroupFilter =
              groupFilter.copyWith(filterState: newGroupFilterState);
          final newGroupFilters = ([...?group.state]..replaceRange(
              groupIndex,
              groupIndex + 1,
              [newGroupFilter],
            ));
          return group.copyWith(state: newGroupFilters);
        }
        return null;
      }
      return null;
    });
    return newFilterState;
  }

  //  {position: 1, state: {"position":1,"state":"true"}}, {position: 1, state: {"position":2,"state":"true"}}])
  FilterChange? _buildGroupChange(String value) {
    final map = jsonDecode(value);
    final change = FilterChange.fromJson(map);
    if (change.position != null && change.state != null) {
      return change;
    }
    return null;
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

@riverpod
class LocalSourceListRefreshSignal extends _$LocalSourceListRefreshSignal
    with StateProviderMixin<int?> {
  @override
  int? build() => 0;
}
