// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/endpoints.dart';
import '../../../constants/enum.dart';
import '../../../global_providers/global_providers.dart';
import '../../../utils/classes/trace/trace_model.dart';
import '../../../utils/classes/trace/trace_ref.dart';
import '../../../utils/cover/cover_cache_manager.dart';
import '../../../utils/storage/dio/dio_client.dart';
import '../../library/domain/category/category_model.dart';
import '../domain/chapter/chapter_model.dart';
import '../domain/chapter_batch/chapter_batch_model.dart';
import '../domain/chapter_patch/chapter_put_model.dart';
import '../domain/manga/manga_model.dart';

part 'manga_book_repository.g.dart';

class MangaBookRepository {
  const MangaBookRepository(this.dioClient);

  final DioClient dioClient;
  Future<void> addMangaToLibrary(String mangaId) =>
      dioClient.get(MangaUrl.library(mangaId));
  Future<void> removeMangaFromLibrary(String mangaId) {
    CoverCacheManager().onRemoveFromLibrary(mangaId);
    return dioClient.delete(MangaUrl.library(mangaId));
  }

  Future<void> modifyBulkChapters({ChapterBatch? batch}) =>
      dioClient.post(MangaUrl.chapterBatch, data: batch?.toJson());

  Future<List<Chapter>?> batchQueryChapter({
    required List<int> chapterIds,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<List<Chapter>, Chapter>(
        MangaUrl.chapterBatchQuery,
        data: {"chapterIds": chapterIds},
        decoder: (e) =>
            e is Map<String, dynamic> ? Chapter.fromJson(e) : Chapter(),
        cancelToken: cancelToken,
      ))
          .data;

  // Mangas
  Future<Manga?> getManga({
    required String mangaId,
    bool onlineFetch = false,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<Manga, Manga?>(
        MangaUrl.fullWithId(mangaId),
        queryParameters: {"onlineFetch": onlineFetch},
        decoder: (e) => e is Map<String, dynamic> ? Manga.fromJson(e) : null,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            "trace": TraceInfo(
              type: TraceType.mangaDetail.name,
              sourceId: TraceRef.get(mangaId),
            )
          },
        ),
      ))
          .data;

  Future<String?> getMangaRealUrl({
    required String mangaId,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<Manga, Manga?>(
        MangaUrl.realUrl(mangaId),
        decoder: (e) => e is Map<String, dynamic> ? Manga.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data
          ?.realUrl;

  // Chapters

  Future<Chapter?> getChapter({
    required String mangaId,
    required String chapterIndex,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<Chapter, Chapter?>(
        MangaUrl.chapterWithIndex(mangaId, chapterIndex),
        decoder: (e) => e is Map<String, dynamic> ? Chapter.fromJson(e) : null,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            "trace": TraceInfo(
              type: TraceType.chapterDetail.name,
              sourceId: TraceRef.get(mangaId),
            )
          },
        ),
      ))
          .data;

  Future<String?> getChapterRealUrl({
    required String mangaId,
    required String chapterIndex,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<Chapter, Chapter?>(
        MangaUrl.chapterRealUrlWithIndex(mangaId, chapterIndex),
        decoder: (e) => e is Map<String, dynamic> ? Chapter.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data
          ?.realUrl;

  Future<void> chapterModify({
    required ChapterModifyInput input,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<Chapter, Chapter?>(
        MangaUrl.chapterModify,
        data: jsonEncode(input.toJson()),
        cancelToken: cancelToken,
      ));

  Future<void> patchMangaMeta({
    required String mangaId,
    required String key,
    required dynamic value,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.patch<Chapter, Chapter?>(
        MangaUrl.meta(mangaId),
        data: FormData.fromMap({
          "key": key,
          "value": value?.toString(),
          "remove": value == null ? "true" : "false",
        }),
        cancelToken: cancelToken,
      ));

  Future<List<Chapter>?> getChapterList({
    required String mangaId,
    bool onlineFetch = false,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<List<Chapter>, Chapter>(
        MangaUrl.chapters(mangaId),
        queryParameters: {"onlineFetch": onlineFetch},
        decoder: (e) =>
            e is Map<String, dynamic> ? Chapter.fromJson(e) : Chapter(),
        cancelToken: cancelToken,
        options: Options(
          extra: {
            "trace": TraceInfo(
              type: TraceType.chapterList.name,
              sourceId: TraceRef.get(mangaId),
            )
          },
        ),
      ))
          .data;

  Future<List<Category>?> getMangaCategoryList({
    required String mangaId,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<List<Category>, Category>(
        MangaUrl.category(mangaId),
        decoder: (e) =>
            e is Map<String, dynamic> ? Category.fromJson(e) : Category(),
        cancelToken: cancelToken,
      ))
          .data;
  Future<void> addMangaToCategory(String mangaId, String categoryId) =>
      dioClient.get(MangaUrl.categoryId(mangaId, categoryId));
  Future<void> removeMangaFromCategory(String mangaId, String categoryId) =>
      dioClient.delete(MangaUrl.categoryId(mangaId, categoryId));
  Future<void> updateMangaCategory(
          String mangaId, List<String> categoryIdList) =>
      dioClient.post(
        MangaUrl.updateCategory(mangaId),
        data: {"categoryIdList": categoryIdList},
      );

  //  History
  Future<List<Manga>?> getMangasFromHistory({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<List<Manga>, Manga>(
        HistoryUrl.list,
        decoder: (e) => e is Map<String, dynamic> ? Manga.fromJson(e) : Manga(),
      ))
          .data;

  Future<void> batchDeleteHistory(List<int> mangaIds) => dioClient
      .delete(HistoryUrl.batchDelete, data: jsonEncode({'mangaIds': mangaIds}));

  Future<void> clearHistory(int lastReadAt) => dioClient.delete(
      HistoryUrl.clear,
      data: jsonEncode(
          lastReadAt == -1 ? {'clearAll': true} : {'lastReadAt': lastReadAt}));
}

@riverpod
MangaBookRepository mangaBookRepository(MangaBookRepositoryRef ref) =>
    MangaBookRepository(ref.watch(dioClientKeyProvider));
