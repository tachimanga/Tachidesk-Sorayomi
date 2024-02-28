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
import '../../../../utils/storage/dio/dio_client.dart';
import '../../domain/migrate/migrate_model.dart';

part 'migrate_repository.g.dart';

class MigrateRepository {
  final DioClient dioClient;

  MigrateRepository(this.dioClient);

  Future<MigrateInfo?> info({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<MigrateInfo, MigrateInfo?>(
        MigrateUrl.info,
        decoder: (e) =>
            e is Map<String, dynamic> ? MigrateInfo.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;

  Future<MigrateSourceList?> sourceList({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<MigrateSourceList, MigrateSourceList?>(
        MigrateUrl.sourceList,
        decoder: (e) =>
            e is Map<String, dynamic> ? MigrateSourceList.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;

  Future<MigrateMangaList?> mangaList({
    required String sourceId,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<MigrateMangaList, MigrateMangaList?>(
        MigrateUrl.mangaList,
        queryParameters: {"sourceId": sourceId},
        decoder: (e) =>
            e is Map<String, dynamic> ? MigrateMangaList.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> doMigrate({
    required MigrateRequest param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        MigrateUrl.doMigrate,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
MigrateRepository migrateRepository(MigrateRepositoryRef ref) =>
    MigrateRepository(ref.watch(dioClientKeyProvider));
