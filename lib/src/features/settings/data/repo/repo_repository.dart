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
import '../../../browse_center/domain/extension/extension_model.dart';
import '../../domain/repo/repo_model.dart';

part 'repo_repository.g.dart';

class RepoRepository {
  final DioClient dioClient;

  RepoRepository(this.dioClient);

  Future<List<Repo>?> getRepoList({CancelToken? cancelToken}) async =>
      (await dioClient.get<List<Repo>, Repo>(
        RepoUrl.list,
        decoder: (e) => e is Map<String, dynamic> ? Repo.fromJson(e) : Repo(),
        cancelToken: cancelToken,
      ))
          .data;

  Future<List<Extension>?> checkRepo({
    required AddRepoParam param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<List<Extension>, Extension>(
        RepoUrl.check,
        data: jsonEncode(param.toJson()),
        decoder: (e) =>
            e is Map<String, dynamic> ? Extension.fromJson(e) : Extension(),
        cancelToken: cancelToken,
      ))
          .data;

  Future<Repo?> createRepo({
    required AddRepoParam param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<Repo, Repo?>(
        RepoUrl.create,
        data: jsonEncode(param.toJson()),
        decoder: (e) => e is Map<String, dynamic> ? Repo.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> deleteRepo({
    required int repoId,
    CancelToken? cancelToken,
  }) async =>
      dioClient.delete(
        RepoUrl.removeWithId(repoId),
        cancelToken: cancelToken,
      );

  Future<void> updateByMetaUrl({
    required UpdateByMetaUrlParam param,
    CancelToken? cancelToken,
  }) async =>
      dioClient.post<Repo, Repo?>(
        RepoUrl.updateByMetaUrl,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      );
}

@riverpod
RepoRepository repoRepository(RepoRepositoryRef ref) =>
    RepoRepository(ref.watch(dioClientKeyProvider));
