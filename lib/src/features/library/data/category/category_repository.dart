// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/endpoints.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/storage/dio/dio_client.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../../domain/category/category_model.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  final DioClient dioClient;

  CategoryRepository(this.dioClient);

  Future<List<Category>?> getCategoryList({CancelToken? cancelToken}) async =>
      (await dioClient.get<List<Category>, Category>(
        CategoryUrl.category,
        decoder: (e) =>
            e is Map<String, dynamic> ? Category.fromJson(e) : Category(),
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> createCategory({
    required Category category,
    CancelToken? cancelToken,
  }) =>
      dioClient.post(
        CategoryUrl.category,
        data: FormData.fromMap(category.toJson().filterOutNulls),
        cancelToken: cancelToken,
      );

  Future<void> editCategory({
    required Category category,
    CancelToken? cancelToken,
  }) async =>
      category.id != null
          ? await dioClient.patch(
              CategoryUrl.withId(category.id!),
              data: FormData.fromMap(category.toJson().filterOutNulls),
              cancelToken: cancelToken,
            )
          : null;

  Future<void> deleteCategory({
    required Category category,
    CancelToken? cancelToken,
  }) async =>
      (category.id != null)
          ? dioClient.delete(
              CategoryUrl.withId(category.id!),
              cancelToken: cancelToken,
            )
          : null;

  Future<void> reorderCategory({
    required int from,
    required int to,
  }) =>
      dioClient.patch(
        CategoryUrl.reorder,
        data: FormData.fromMap({"from": from, "to": to}),
      );

  Future<void> updateMeta({
    required int categoryId,
    required String key,
    required String? value,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        CategoryUrl.meta(categoryId),
        data: jsonEncode({
          'key': key,
          'value': value,
        }),
        cancelToken: cancelToken,
      ));

  //  Manga
  Future<List<Manga>?> getMangasFromCategory({
    required int categoryId,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<List<Manga>, Manga>(
        CategoryUrl.withId(categoryId),
        decoder: (e) => e is Map<String, dynamic> ? Manga.fromJson(e) : Manga(),
      ))
          .data;
}

@riverpod
CategoryRepository categoryRepository(CategoryRepositoryRef ref) =>
    CategoryRepository(ref.watch(dioClientKeyProvider));
