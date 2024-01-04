// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:queue/queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
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
AsyncValue<List<QuickSearchResult>> quickSearchResults(
    QuickSearchResultsRef ref,
    {String? query,
    bool? pin}) {
  if (query.isBlank == true) {
    return const AsyncValue.data([]);
  }
  //print("SEARCH quickSearchResults $query pin:$pin");
  final sourceMapData = ref.watch(sourceMapFilteredProvider);

  final sourceMap = {...?sourceMapData.valueOrNull}..remove("lastUsed");
  final sourceList = sourceMap.values.fold(
    <Source>[],
    (prev, cur) => [...prev, ...cur],
  );
  final List<QuickSearchResult> sourceMangaListPairList = [];

  final onlySearchPinSource = ref.watch(onlySearchPinSourceProvider);
  final pinSourceIdList = ref.watch(pinSourceIdListProvider);
  final pinSourceIdSet = {...?pinSourceIdList};

  for (Source source in sourceList) {
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
  return sourceMapData.copyWithData((_) => sourceMangaListPairList);
}
