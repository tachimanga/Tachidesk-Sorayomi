// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/repo/repo_repository.dart';
import '../domain/repo/repo_model.dart';

part 'edit_repo_controller.g.dart';

@riverpod
class RepoController extends _$RepoController {
  @override
  Future<List<Repo>?> build() async {
    final token = CancelToken();
    ref.onDispose(token.cancel);
    final result =
        await ref.watch(repoRepositoryProvider).getRepoList(cancelToken: token);
    return result;
  }
}

@riverpod
int repoCount(RepoCountRef ref) {
  final repoList = ref.watch(repoControllerProvider);
  return repoList.valueOrNull?.length ?? 0;
}

