// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:queue/queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/source/source_model.dart';
import '../../source/controller/source_controller.dart';

part 'source_quick_search_controller.g.dart';

class QuickSearchResult {
  Source source;
  AsyncValue<List<Manga>> mangaList;
  QuickSearchResult(this.source, this.mangaList);
}

@riverpod
Queue rateLimitQueue(
  ref, {
  String? query,
  bool? pin,
}) {
  //print("SEARCH rateLimitQueue $query pin:$pin");
  final queue = Queue(
    parallel: 5,
  );
  ref.onDispose(() {
    //print("SEARCH rateLimitQueue onDispose");
    queue.cancel();
  });
  return queue;
}

@riverpod
Future<List<Manga>> sourceQuickSearchMangaList(
  SourceQuickSearchMangaListRef ref,
  String sourceId, {
  String? query,
  bool? pin,
}) async {
  final queue = ref.watch(rateLimitQueueProvider(query: query, pin: pin));
  final sourceRepository = ref.watch(sourceRepositoryProvider);
  final mangaPage = await queue.add(() {
    //print("SEARCH send $sourceId");
    return sourceRepository.getMangaList(
      pageNum: 1,
      sourceId: sourceId,
      sourceType: SourceType.filter,
      query: query,
    );
  });
  //print("SEARCH succ $sourceId");
  return [...?(mangaPage?.mangaList)];
}

@riverpod
AsyncValue<Pair<Map<String, List<Source>>?, List<String?>?>>
    sourceMapFilteredWithSort(SourceMapFilteredWithSortRef ref) {
  final sourceMapData = ref.watch(sourceMapFilteredProvider);
  final sourceIdsValue = ref.watch(sourceIdListForSearchProvider);
  final sourceIds = sourceIdsValue.valueOrNull;
  if (sourceIds == null) {
    return const AsyncLoading();
  }
  return sourceMapData.copyWithData((e) => Pair(first: e, second: sourceIds));
}

@riverpod
AsyncValue<List<QuickSearchResult>> quickSearchResults(
    QuickSearchResultsRef ref,
    {String? query,
    bool? pin}) {
  if (query.isBlank == true) {
    return const AsyncValue.data([]);
  }
  //print("SEARCH quickSearchResults $query pin:$pin");
  final sourceMapFilteredWithSort =
      ref.watch(sourceMapFilteredWithSortProvider);
  final pair = sourceMapFilteredWithSort.valueOrNull;
  final sourceMapData = pair?.first;
  final sourceIds = pair?.second ?? [];

  final sourceMap = {...?sourceMapData}..remove("lastUsed");
  final pinnedList = sourceMap.remove("pinned");
  final sourceList = sourceMap.values.fold(
    <Source>[],
    (prev, cur) => [...prev, ...cur],
  );

  final sortedPinnedList = sortedSourceListByIds(pinnedList, sourceIds);
  final sortedLeftList = sortedSourceListByIds(sourceList, sourceIds);
  final sortedSourceList = [...sortedPinnedList, ...sortedLeftList];
  final List<QuickSearchResult> sourceMangaListPairList = [];

  final onlySearchPinSource = ref.watch(onlySearchPinSourceProvider);
  final pinSourceIdList = ref.watch(pinSourceIdListProvider);
  final pinSourceIdSet = {...?pinSourceIdList};

  for (Source source in sortedSourceList) {
    if (source.id.isNotBlank) {
      if (onlySearchPinSource == true && !pinSourceIdSet.contains(source.id!)) {
        continue;
      }
      final mangaList = ref.watch(
        sourceQuickSearchMangaListProvider(source.id!, query: query, pin: pin),
      );
      sourceMangaListPairList.add(QuickSearchResult(source, mangaList));
    }
  }

  // print("Search sourceMangaListPairList ${sourceMangaListPairList.length}");
  // ref.onDispose(() {
  //   print("SEARCH quickSearchResults ondispose");
  // });
  return sourceMapFilteredWithSort.copyWithData((_) => sourceMangaListPairList);
}

List<Source> sortedSourceListByIds(
    List<Source>? sourceList, List<String?> sourceIds) {
  if (sourceList == null) {
    return [];
  }
  final sourceListMap = <String, Source>{};
  for (final s in sourceList) {
    sourceListMap[s.id ?? ""] = s;
  }
  final sortedSourceList = <Source>[];
  for (final id in sourceIds) {
    final source = sourceListMap.remove(id);
    if (source != null) {
      sortedSourceList.add(source);
    }
  }
  sortedSourceList.addAll(sourceListMap.values);
  return sortedSourceList;
}
