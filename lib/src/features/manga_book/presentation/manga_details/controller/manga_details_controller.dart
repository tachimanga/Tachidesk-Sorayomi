// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../library/domain/category/category_model.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';

part 'manga_details_controller.g.dart';

@riverpod
class MangaWithId extends _$MangaWithId {
  @override
  Future<Manga?> build({required String mangaId}) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await ref
        .watch(mangaBookRepositoryProvider)
        .getManga(mangaId: mangaId, cancelToken: token);
    ref.keepAlive();

    final pipe = ref.watch(getMagicPipeProvider);
    logEvent2(pipe, "LOAD_MANGA", {
      "x": result?.source?.extPkgName?.replaceAll("eu.kanade.tachiyomi.extension.", "") ?? "-",
      "y": "${result?.source?.lang?.code}",
      "z": "${result?.source?.id}",
    });
    return result;
  }

  Future<void> refresh([bool onlineFetch = false]) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await AsyncValue.guard(
      () => ref.watch(mangaBookRepositoryProvider).getManga(
            mangaId: mangaId,
            cancelToken: token,
            onlineFetch: onlineFetch,
          ),
    );
    ref.keepAlive();
    state = result;
  }
}

@riverpod
class MangaChapterList extends _$MangaChapterList {
  @override
  Future<List<Chapter>?> build({required String mangaId}) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await ref.watch(mangaBookRepositoryProvider).getChapterList(
          mangaId: mangaId,
          cancelToken: token,
          onlineFetch: false,
        );
    ref.keepAlive();
    return result;
  }

  Future<void> refresh([bool onlineFetch = false]) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await AsyncValue.guard(
      () => ref.read(mangaBookRepositoryProvider).getChapterList(
            mangaId: mangaId,
            cancelToken: token,
            onlineFetch: onlineFetch,
          ),
    );
    ref.keepAlive();
    state = result;
  }

  void updateChapter(int index, Chapter chapter) {
    try {
      final newList = [...?state.valueOrNull];
      newList[index] = chapter;
      state = AsyncData<List<Chapter>?>(newList).copyWithPrevious(state);
    } catch (e) {
      //
    }
  }
}

@riverpod
Set<String> mangaScanlatorList(MangaScanlatorListRef ref,
    {required String mangaId}) {
  final chapterList = ref.watch(mangaChapterListProvider(mangaId: mangaId));
  final scanlatorList = <String>{};
  chapterList.whenData((data) {
    if (data == null) return;
    for (final chapter in data) {
      if (chapter.scanlator.isNotBlank) {
        scanlatorList.add(chapter.scanlator!);
      }
    }
  });
  return scanlatorList;
}

@riverpod
class MangaChapterFilterScanlator extends _$MangaChapterFilterScanlator {
  @override
  List<String> build({required String mangaId}) {
    final manga = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final str = manga.valueOrNull?.meta?.scanlator;
    //print("MangaChapterFilterScanlator init: $str");
    if (str == null || str.isEmpty) {
      return []; // [] for select all
    }
    if (str.startsWith("{")) {
      final e = json.decode(str);
      if (e is Map<String, dynamic>) {
        final meta = ScanlatorMeta.fromJson(e);
        if (meta.list != null) {
          return meta.list!;
        }
      }
    }
    return [str];
  }

  void update(List<String> scanlators) async {
    final str = json.encode(ScanlatorMeta(list: scanlators));
    //print("MangaChapterFilterScanlator update: $str");
    await AsyncValue.guard(
          () => ref.read(mangaBookRepositoryProvider).patchMangaMeta(
        mangaId: mangaId,
        key: MangaMetaKeys.scanlator.key,
        value: str,
      ),
    );
    ref.invalidate(mangaWithIdProvider(mangaId: mangaId));
    state = scanlators;
  }
}

@riverpod
AsyncValue<List<Chapter>?> mangaChapterListWithFilter(
  MangaChapterListWithFilterRef ref, {
  required String mangaId,
}) {
  final chapterList = ref.watch(mangaChapterListProvider(mangaId: mangaId));
  final chapterFilterUnread = ref.watch(mangaChapterFilterUnreadProvider);
  final chapterFilterDownloaded =
      ref.watch(mangaChapterFilterDownloadedProvider);
  final chapterFilterBookmark = ref.watch(mangaChapterFilterBookmarkedProvider);
  final sortedBy = ref.watch(mangaChapterSortProvider);
  final sortedDirection =
      ref.watch(mangaChapterSortDirectionProvider).ifNull(true);
  final chapterFilterScanlators =
    ref.watch(mangaChapterFilterScanlatorProvider(mangaId: mangaId));
  final selectedScanlatorSet = {...chapterFilterScanlators};

  bool applyChapterFilter(Chapter chapter) {
    if (chapterFilterUnread != null &&
        (chapterFilterUnread ^ !(chapter.read.ifNull()))) {
      return false;
    }

    if (chapterFilterDownloaded != null &&
        (chapterFilterDownloaded ^ (chapter.downloaded.ifNull()))) {
      return false;
    }

    if (chapterFilterBookmark != null &&
        (chapterFilterBookmark ^ (chapter.bookmarked.ifNull()))) {
      return false;
    }

    if (selectedScanlatorSet.isNotEmpty
        && !selectedScanlatorSet.contains(chapter.scanlator)) {
      return false;
    }
    return true;
  }

  int applyChapterSort(Chapter m1, Chapter m2) {
    final sortDirToggle = (sortedDirection ? 1 : -1);
    switch (sortedBy) {
      case ChapterSort.fetchedDate:
        return (m1.fetchedAt ?? 0).compareTo(m2.fetchedAt ?? 0) * sortDirToggle;
      case ChapterSort.source:
        return (m1.index ?? 0).compareTo(m2.index ?? 0) * sortDirToggle;
      default:
        return 0;
    }
  }

  return chapterList.copyWithData(
    (data) => [...?data?.where(applyChapterFilter)]..sort(applyChapterSort),
  );
}

@riverpod
Chapter? firstUnreadInFilteredChapterList(
  FirstUnreadInFilteredChapterListRef ref, {
  required String mangaId,
}) {
  final isAscSorted = ref.watch(mangaChapterSortDirectionProvider) ??
      DBKeys.chapterSortDirection.initial;
  final filteredList = ref
      .watch(mangaChapterListWithFilterProvider(mangaId: mangaId))
      .valueOrNull;
  if (filteredList == null) {
    return null;
  } else {
    var maxLastPageRead = -1;
    Chapter? lastReadChapter;
    final list = isAscSorted ? filteredList : filteredList.reversed;
    for (final chapter in list) {
      final curr = chapter.lastReadAt ?? 0;
      if (curr > maxLastPageRead) {
        maxLastPageRead = curr;
        lastReadChapter = chapter;
      }
    }
    if (lastReadChapter?.read == true) {
      var find = false;
      for (final chapter in list) {
        if (find) {
          lastReadChapter = chapter;
          break;
        }
        if (chapter == lastReadChapter) {
          find = true;
        }
      }
    }
    return lastReadChapter;
    /*
    if (isAscSorted) {
      return filteredList
          .firstWhereOrNull((element) => !element.read.ifNull(true));
    } else {
      return filteredList
          .lastWhereOrNull((element) => !element.read.ifNull(true));
    }
    */
  }
}

@riverpod
Pair<Chapter?, Chapter?>? getPreviousAndNextChapters(
  GetPreviousAndNextChaptersRef ref, {
  required String mangaId,
  required String chapterIndex,
}) {
  final isAscSorted = ref.watch(mangaChapterSortDirectionProvider) ??
      DBKeys.chapterSortDirection.initial;
  final filteredList = ref
      .watch(mangaChapterListWithFilterProvider(mangaId: mangaId))
      .valueOrNull;
  if (filteredList == null) {
    return null;
  } else {
    final currentChapterIndex = filteredList
        .indexWhere((element) => "${element.index}" == chapterIndex);
    final prevChapter =
        currentChapterIndex > 0 ? filteredList[currentChapterIndex - 1] : null;
    final nextChapter = currentChapterIndex < (filteredList.length - 1)
        ? filteredList[currentChapterIndex + 1]
        : null;
    return Pair(
      first: isAscSorted ? nextChapter : prevChapter,
      second: isAscSorted ? prevChapter : nextChapter,
    );
  }
}

@riverpod
class MangaChapterSort extends _$MangaChapterSort
    with SharedPreferenceEnumClientMixin<ChapterSort> {
  @override
  ChapterSort? build() => initialize(
        ref,
        key: DBKeys.chapterSort.name,
        initial: DBKeys.chapterSort.initial,
        enumList: ChapterSort.values,
      );
}

@riverpod
class MangaChapterSortDirection extends _$MangaChapterSortDirection
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.chapterSortDirection.name,
        initial: DBKeys.chapterSortDirection.initial,
      );
}

@riverpod
class MangaChapterFilterDownloaded extends _$MangaChapterFilterDownloaded
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.chapterFilterDownloaded.name,
        initial: DBKeys.chapterFilterDownloaded.initial,
      );
}

@riverpod
class MangaChapterFilterUnread extends _$MangaChapterFilterUnread
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.chapterFilterUnread.name,
        initial: DBKeys.chapterFilterUnread.initial,
      );
}

@riverpod
class MangaChapterFilterBookmarked extends _$MangaChapterFilterBookmarked
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.chapterFilterBookmarked.name,
        initial: DBKeys.chapterFilterBookmarked.initial,
      );
}

@riverpod
class MangaCategoryList extends _$MangaCategoryList {
  @override
  FutureOr<Map<String, Category>?> build(String mangaId) async {
    final result = await ref
        .watch(mangaBookRepositoryProvider)
        .getMangaCategoryList(mangaId: mangaId);
    return {
      for (Category i in (result ?? <Category>[])) "${i.id ?? ''}": i,
    };
  }

  Future<void> refresh() async {
    final result = await AsyncValue.guard(() => ref
        .watch(mangaBookRepositoryProvider)
        .getMangaCategoryList(mangaId: mangaId));
    state = result.copyWithData((data) => {
          for (Category i in (data ?? <Category>[])) "${i.id ?? ''}": i,
        });
  }
}
