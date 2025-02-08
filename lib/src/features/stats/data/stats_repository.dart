// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/endpoints.dart';
import '../../../global_providers/global_providers.dart';
import '../../../utils/storage/dio/dio_client.dart';
import '../domain/stats_model.dart';

part 'stats_repository.g.dart';

class StatsRepository {
  final DioClient dioClient;

  StatsRepository(this.dioClient);

  Future<ReadTimeStats?> queryReadTimeStats({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<ReadTimeStats, ReadTimeStats?>(
        StatsUrl.readTime,
        decoder: (e) =>
            e is Map<String, dynamic> ? ReadTimeStats.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
StatsRepository statsRepository(StatsRepositoryRef ref) =>
    StatsRepository(ref.watch(dioClientKeyProvider));
