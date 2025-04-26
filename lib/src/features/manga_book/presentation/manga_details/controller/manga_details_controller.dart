// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../library/domain/category/category_model.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';
import 'manga_chapter_controller.dart';

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
    return result;
  }

  Future<Manga?> refresh([bool onlineFetch = false]) async {
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
    return result.valueOrNull;
  }

  Future<void> refreshSilently() async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await AsyncValue.guard(
      () => ref.watch(mangaBookRepositoryProvider).getManga(
            mangaId: mangaId,
            cancelToken: token,
            onlineFetch: false,
          ),
    );
    if (result is AsyncError) {
      log("[flush]MangaWithId refresh error $result");
      return;
    }
    ref.keepAlive();
    state = result;
  }

  void updateManga(Manga manga) {
    state = AsyncData(manga);
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

  Future<void> refreshSilently() async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await AsyncValue.guard(
      () => ref.read(mangaBookRepositoryProvider).getChapterList(
            mangaId: mangaId,
            cancelToken: token,
            onlineFetch: false,
          ),
    );
    if (result is AsyncError) {
      log("[flush]MangaChapterList refresh error $result");
      return;
    }
    ref.keepAlive();
    state = result;
  }
}

@riverpod
List<Pair<String, int>> mangaScanlatorList(Ref ref, {required String mangaId}) {
  final chapterList = ref.watch(mangaChapterListProvider(mangaId: mangaId));
  final Map<String, int> map = {};
  chapterList.whenData((data) {
    if (data == null) return;
    for (final chapter in data) {
      if (chapter.scanlator?.isNotEmpty == true) {
        final key = chapter.scanlator!;
        map[key] = (map[key] ?? 0) + 1;
      }
    }
  });
  return map.entries.map((e) => Pair(first: e.key, second: e.value)).toList();
}

@riverpod
class MangaChapterFilterScanlator extends _$MangaChapterFilterScanlator {
  Timer? debounce;

  @override
  ScanlatorMeta build({required String mangaId}) {
    final manga = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final str = manga.valueOrNull?.meta?.scanlator;
    //print("MangaChapterFilterScanlator init: $str");
    if (str == null || str.isEmpty) {
      return ScanlatorMeta(list: []); // [] for select all
    }
    if (str.startsWith("{")) {
      final e = json.decode(str);
      if (e is Map<String, dynamic>) {
        return ScanlatorMeta.fromJson(e);
      }
    }
    return ScanlatorMeta(list: [str]);
  }

  void update(ScanlatorMeta meta) {
    state = meta;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final str = json.encode(meta);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.scanlator.key,
                value: str,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refreshSilently();
        });
      },
    );
  }
}

@riverpod
class FakeMangaChapterFilterScanlator
    extends _$FakeMangaChapterFilterScanlator {
  @override
  ScanlatorMeta build({required String mangaId}) {
    return ScanlatorMeta(list: []);
  }

  void update(ScanlatorMeta meta) {
    state = meta;
  }
}

@riverpod
class MangaChapterListQuery extends _$MangaChapterListQuery {
  @override
  String? build({required String mangaId}) {
    return null;
  }

  void update(String? query) async {
    state = query;
  }
}

@riverpod
AsyncValue<List<Chapter>?> mangaChapterListWithFilter(
  MangaChapterListWithFilterRef ref, {
  required String mangaId,
}) {
  final chapterList = ref.watch(mangaChapterListProvider(mangaId: mangaId));
  // filter options
  final chapterFilterUnread =
      ref.watch(mangaChapterFilterUnreadWithMangaIdProvider(mangaId: mangaId));
  final chapterFilterDownloaded = ref
      .watch(mangaChapterFilterDownloadedWithMangaIdProvider(mangaId: mangaId));
  final chapterFilterBookmark = ref
      .watch(mangaChapterFilterBookmarkedWithMangaIdProvider(mangaId: mangaId));
  // sort options
  final sortedBy =
      ref.watch(mangaChapterSortWithMangaIdProvider(mangaId: mangaId));
  final sortedDirection = ref
      .watch(mangaChapterSortDirectionWithMangaIdProvider(mangaId: mangaId))
      .ifNull(true);
  // scanlators
  final scanlatorMeta =
      ref.watch(mangaChapterFilterScanlatorProvider(mangaId: mangaId));

  // query
  final query = ref.watch(mangaChapterListQueryProvider(mangaId: mangaId));

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

    if (query?.isNotEmpty == true && chapter.name?.query(query) != true) {
      return false;
    }

    return true;
  }

  int applyChapterSort(Chapter m1, Chapter m2) {
    switch (sortedBy) {
      case ChapterSort.source:
        return (m1.index ?? 0).compareTo(m2.index ?? 0);
      case ChapterSort.fetchedDate:
        final i = (m1.uploadDate ?? 0).compareTo(m2.uploadDate ?? 0);
        return i != 0 ? i : (m1.index ?? 0).compareTo(m2.index ?? 0);
      case ChapterSort.chapterName:
        final i = compareNatural(m1.name ?? "", m2.name ?? "");
        return i != 0 ? i : (m1.index ?? 0).compareTo(m2.index ?? 0);
      default:
        return 0;
    }
  }

  return chapterList.copyWithData(
    (data) {
      final list0 = _removeDuplicateChapters(data, scanlatorMeta);
      final list = [...?list0?.where(applyChapterFilter)]
        ..sort(applyChapterSort);
      return sortedDirection ? list : list.reversed.toList();
    },
  );
}

List<Chapter>? _removeDuplicateChapters(
    List<Chapter>? list, ScanlatorMeta meta) {
  if (list == null) {
    return list;
  }
  final type = ScanlatorFilterType.safeFromIndex(meta.type);
  if (type == ScanlatorFilterType.filter) {
    return _removeDuplicateChaptersByFilter(list, meta);
  }

  final allScanlatorSet = <String>{};
  for (final chapter in list) {
    if (chapter.scanlator != null) {
      allScanlatorSet.add(chapter.scanlator!);
    }
  }
  final allScanlators = allScanlatorSet.toList();

  if (allScanlators.isEmpty) {
    return list;
  }

  List<Chapter> window = [];
  List<List<Chapter>> windows = [];

  void resetWindow() {
    if (window.isNotEmpty) {
      windows.add([...window]);
      window.clear();
    }
  }

  List<Chapter> chapterList = [];

  for (final chapter in list) {
    if (chapter.scanlator == null) {
      chapterList.add(chapter);
      resetWindow();
      continue;
    }
    if ((chapter.chapterNumber ?? -1) < 0) {
      chapterList.add(chapter);
      resetWindow();
      continue;
    }
    if (window.isNotEmpty &&
        chapter.chapterNumber != window.first.chapterNumber) {
      resetWindow();
    }
    window.add(chapter);
  }
  // last window
  resetWindow();

  for (final window in windows) {
    if (window.length == 1) {
      chapterList.add(window.first);
      continue;
    }
    Map<String, Chapter> chapterMap = {};
    for (final chapter in window) {
      chapterMap[chapter.scanlator!] = chapter;
    }
    final chapter = _pickFirstChapter(chapterMap, meta.priority) ??
        _pickFirstChapter(chapterMap, allScanlators) ??
        window.first;
    chapterList.add(chapter);
  }
  return chapterList;
}

Chapter? _pickFirstChapter(
    Map<String, Chapter> chapterMap, List<String>? priorityList) {
  if (priorityList == null) {
    return null;
  }
  for (final scanlator in priorityList) {
    final chapter = chapterMap[scanlator];
    if (chapter != null) {
      return chapter;
    }
  }
  return null;
}

List<Chapter>? _removeDuplicateChaptersByFilter(
    List<Chapter>? list, ScanlatorMeta meta) {
  final selectedScanlatorSet = {...?meta.list};
  if (selectedScanlatorSet.isEmpty) {
    return list;
  }
  return list?.where((chapter) {
    if (chapter.scanlator?.isNotEmpty == true &&
        !selectedScanlatorSet.contains(chapter.scanlator)) {
      return false;
    }
    return true;
  }).toList();
}

@riverpod
Chapter? firstUnreadInFilteredChapterList(
  FirstUnreadInFilteredChapterListRef ref, {
  required String mangaId,
}) {
  final isAscSorted = ref.watch(
          mangaChapterSortDirectionWithMangaIdProvider(mangaId: mangaId)) ??
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
    if (lastReadChapter?.read == true && lastReadChapter?.lastPageRead == 0) {
      var find = false;
      for (final chapter in list) {
        if (find) {
          lastReadChapter = chapter.copyWith(resumeFlag: true);
          break;
        }
        if (chapter == lastReadChapter) {
          find = true;
        }
      }
    }
    return lastReadChapter;
  }
}

@riverpod
Pair<Chapter?, Chapter?>? getPreviousAndNextChapters(
  GetPreviousAndNextChaptersRef ref, {
  required String mangaId,
  required String chapterIndex,
}) {
  final isAscSorted = ref.watch(
          mangaChapterSortDirectionWithMangaIdProvider(mangaId: mangaId)) ??
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
