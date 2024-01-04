// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/locale_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/source/source_model.dart';
import 'source_query_controller.dart';

part 'source_controller.g.dart';

@riverpod
Future<List<Source>?> sourceList(SourceListRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(sourceRepositoryProvider)
      .getSourceList(cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
AsyncValue<Map<String, List<Source>>> sourceMap(SourceMapRef ref) {
  final sourceMap = <String, List<Source>>{};
  final sourceListData = ref.watch(sourceListProvider);
  final sourceLastUsed = ref.watch(sourceLastUsedProvider);
  for (final e in [...?sourceListData.valueOrNull]) {
    sourceMap.update(
      e.lang?.code ?? "other",
      (value) => [...value, e],
      ifAbsent: () => [e],
    );
    if (e.id == sourceLastUsed) sourceMap["lastUsed"] = [e];
  }
  return sourceListData.copyWithData((e) => sourceMap);
}

@riverpod
List<String> sourceFilterLangList(SourceFilterLangListRef ref) {
  return [
    ...?(ref.watch(sourceMapProvider).valueOrNull
          ?..remove("localsourcelang")
          ..remove("lastUsed"))
        ?.keys
  ]..sort();
}

@riverpod
AsyncValue<Map<String, List<Source>>?> sourceMapFiltered(
    SourceMapFilteredRef ref) {
  final sourceMapFiltered = <String, List<Source>>{};
  final sourceMapData = ref.watch(sourceMapProvider);
  final sourceMap = {...?sourceMapData.valueOrNull};
  final enabledLangList = [...?ref.watch(sourceLanguageFilterProvider)];
  print('enabledLangList $enabledLangList');
  // if (enabledLangList.contains("all")) {
  //   return sourceMapData;
  // }
  for (final e in enabledLangList) {
    if (sourceMap.containsKey(e)) sourceMapFiltered[e] = sourceMap[e]!;
  }

  final pinSourceIdList = ref.watch(pinSourceIdListProvider);
  final pinSourceIdSet = {...?pinSourceIdList};
  final pinSourceList = <Source>[];

  for (var entry in sourceMapFiltered.entries) {
    if (entry.key == "lastUsed") {
      continue;
    }
    final keep = <Source>[];
    for (final s in entry.value) {
      if (pinSourceIdSet.contains(s.id)) {
        pinSourceList.add(s);
      } else {
        keep.add(s);
      }
    }
    sourceMapFiltered[entry.key] = keep;
  }
  sourceMapFiltered["pinned"] = pinSourceList;

  final query = ref.watch(sourceQueryProvider);
  if (query.isNotBlank) {
    for (var entry in sourceMapFiltered.entries) {
      sourceMapFiltered[entry.key] =
          entry.value.where((element) => element.name.query(query)).toList();
    }
  }

  return sourceMapData.copyWithData((e) => sourceMapFiltered);
}

@riverpod
class SourceLanguageFilter extends _$SourceLanguageFilter
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
        ref,
        key: DBKeys.sourceLanguageFilter.name,
        initial: DBKeys.sourceLanguageFilter.initial + ref.watch(sysPreferLocalesProvider),
      );
}

@riverpod
class SourceLastUsed extends _$SourceLastUsed
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: DBKeys.sourceLastUsed.name,
        initial: DBKeys.sourceLastUsed.initial,
      );
}

@riverpod
class PinSourceIdList extends _$PinSourceIdList
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
    ref,
    key: DBKeys.pinSourceIdList.name,
    initial: DBKeys.pinSourceIdList.initial,
  );
}


@riverpod
class OnlySearchPinSource extends _$OnlySearchPinSource
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.onlySearchPinSource.name,
    initial: DBKeys.onlySearchPinSource.initial,
  );
}
