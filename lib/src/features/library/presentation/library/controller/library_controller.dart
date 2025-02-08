// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/category/category_repository.dart';
import '../../../domain/category/category_model.dart';
import '../../category/controller/edit_category_controller.dart';

part 'library_controller.g.dart';

@riverpod
class CategoryMangaListWithId extends _$CategoryMangaListWithId {
  @override
  Future<List<Manga>?> build({required int categoryId}) async =>
      loadMangaList(ref, categoryId);

  Future<List<Manga>?> loadMangaList(
    AutoDisposeAsyncNotifierProviderRef<List<Manga>?> ref,
    int categoryId,
  ) async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result = await ref
        .watch(categoryRepositoryProvider)
        .getMangasFromCategory(categoryId: categoryId, cancelToken: token);
    ref.keepAlive();
    return result;
  }

  Future<void> reloadMangaList() async {
    state = await AsyncValue.guard(() async {
      return loadMangaList(ref, categoryId);
    });
  }
}

bool genreMatches(List<String>? mangaGenreList, List<String>? queryGenreList) {
  Set<String>? mangaSet = mangaGenreList?.map((e) => e.toLowerCase()).toSet();
  Set<String>? querySet =
      queryGenreList?.map((e) => e.toLowerCase().trim()).toSet();
  return (mangaSet?.containsAll(querySet ?? <String>{})).ifNull(true);
}

@riverpod
class CategoryMangaListWithQueryAndFilter
    extends _$CategoryMangaListWithQueryAndFilter {
  @override
  AsyncValue<List<Manga>?> build({required int categoryId}) {
    final mangaList =
        ref.watch(categoryMangaListWithIdProvider(categoryId: categoryId));
    final query = ref.watch(libraryQueryProvider);
    final mangaFilterUnread = ref.watch(libraryMangaFilterUnreadProvider);
    final mangaFilterDownloaded =
        ref.watch(libraryMangaFilterDownloadedProvider);
    final mangaFilterCompleted = ref.watch(libraryMangaFilterCompletedProvider);

    final sortedBy =
        ref.watch(categorySortWithIdProvider(categoryId: categoryId));
    final sortedDirection = ref
        .watch(categorySortDirectionWithIdProvider(categoryId: categoryId))
        .ifNull(true);

    bool applyMangaFilter(Manga manga) {
      if (mangaFilterUnread != null &&
          (mangaFilterUnread ^ manga.unreadCount.isGreaterThan(0))) {
        return false;
      }

      if (mangaFilterDownloaded != null &&
          (mangaFilterDownloaded ^ manga.downloadCount.isGreaterThan(0))) {
        return false;
      }

      if (mangaFilterCompleted != null &&
          (mangaFilterCompleted ^ (manga.status?.title == "COMPLETED"))) {
        return false;
      }

      if (!manga.title.query(query) &&
          !genreMatches(manga.genre, query?.split(','))) {
        return false;
      }

      return true;
    }

    int applyMangaSort(Manga m1, Manga m2) {
      switch (sortedBy) {
        case MangaSort.alphabetical:
          return (m1.title ?? "").compareTo(m2.title ?? "");
        case MangaSort.unread:
          return (m1.unreadCount ?? 0).compareTo(m2.unreadCount ?? 0);
        case MangaSort.dateAdded:
          return (m1.inLibraryAt ?? 0).compareTo(m2.inLibraryAt ?? 0);
        case MangaSort.lastRead:
          return (m2.lastReadAt ?? 0).compareTo(m1.lastReadAt ?? 0);
        case MangaSort.latestChapterFetchAt:
          return (m1.latestChapterFetchAt ?? 0)
              .compareTo(m2.latestChapterFetchAt ?? 0);
        case MangaSort.latestChapterUploadAt:
          return (m1.latestChapterUploadAt ?? 0)
              .compareTo(m2.latestChapterUploadAt ?? 0);
        default:
          return 0;
      }
    }

    return mangaList.map<AsyncValue<List<Manga>?>>(
      data: (e) {
        final list = e.valueOrNull?.where(applyMangaFilter).toList()
          ?..sort(applyMangaSort);
        return AsyncData(sortedDirection ? list : list?.reversed.toList());
      },
      error: (e) => e,
      loading: (e) => e,
    );
  }

  void invalidate() =>
      ref.invalidate(categoryMangaListWithIdProvider(categoryId: categoryId));
}

@riverpod
class LibraryQuery extends _$LibraryQuery with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
class LibraryMangaFilterDownloaded extends _$LibraryMangaFilterDownloaded
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.mangaFilterDownloaded.name,
        initial: DBKeys.mangaFilterDownloaded.initial,
      );
}

@riverpod
class LibraryMangaFilterUnread extends _$LibraryMangaFilterUnread
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.mangaFilterUnread.name,
        initial: DBKeys.mangaFilterUnread.initial,
      );
}

@riverpod
class LibraryMangaFilterCompleted extends _$LibraryMangaFilterCompleted
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.mangaFilterCompleted.name,
        initial: DBKeys.mangaFilterCompleted.initial,
      );
}

@riverpod
class LibraryMangaSort extends _$LibraryMangaSort
    with SharedPreferenceEnumClientMixin<MangaSort> {
  @override
  MangaSort? build() => initialize(
        ref,
        key: DBKeys.mangaSort.name,
        initial: DBKeys.mangaSort.initial,
        enumList: MangaSort.values,
      );
}

@riverpod
class LibraryMangaSortDirection extends _$LibraryMangaSortDirection
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.mangaSortDirection.name,
        initial: DBKeys.mangaSortDirection.initial,
      );
}

@riverpod
class LibraryDisplayMode extends _$LibraryDisplayMode
    with SharedPreferenceEnumClientMixin<DisplayMode> {
  @override
  DisplayMode? build() => initialize(
        ref,
        key: DBKeys.libraryDisplayMode.name,
        initial: DBKeys.libraryDisplayMode.initial,
        enumList: DisplayMode.values,
      );
}

@riverpod
class LibraryShowMangaCount extends _$LibraryShowMangaCount
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.libraryShowMangaCount.name,
        initial: DBKeys.libraryShowMangaCount.initial,
      );
}

@riverpod
class CategorySortWithId extends _$CategorySortWithId {
  Timer? debounce;

  @override
  MangaSort? build({required int categoryId}) {
    final categoryList = ref.watch(categoryControllerProvider);
    final category =
        categoryList.valueOrNull?.where((e) => e.id == categoryId).firstOrNull;

    final globalValue = ref.watch(libraryMangaSortProvider);
    return category?.meta?.sort ?? globalValue;
  }

  void update(MangaSort? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          await ref.read(categoryRepositoryProvider).updateMeta(
                categoryId: categoryId,
                key: CategoryMetaKeys.sort.key,
                value: value?.name,
              );
          await ref
              .read(categoryControllerProvider.notifier)
              .reloadCategories();
        });
      },
    );
  }
}

@riverpod
class CategorySortDirectionWithId extends _$CategorySortDirectionWithId {
  Timer? debounce;

  @override
  bool? build({required int categoryId}) {
    final categoryList = ref.watch(categoryControllerProvider);
    final category =
        categoryList.valueOrNull?.where((e) => e.id == categoryId).firstOrNull;

    final globalValue = ref.watch(libraryMangaSortDirectionProvider);
    return category?.meta?.sortDirection ?? globalValue;
  }

  void update(bool? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          await ref.read(categoryRepositoryProvider).updateMeta(
                categoryId: categoryId,
                key: CategoryMetaKeys.sortDirection.key,
                value: value?.toString(),
              );
          await ref
              .read(categoryControllerProvider.notifier)
              .reloadCategories();
        });
      },
    );
  }
}
