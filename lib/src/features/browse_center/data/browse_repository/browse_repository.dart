// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/endpoints.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/storage/dio/dio_client.dart';
import '../../domain/browse/browse_model.dart';
import '../../domain/migrate/migrate_model.dart';

part 'browse_repository.g.dart';

class BrowseRepository {
  final DioClient dioClient;

  BrowseRepository(this.dioClient);

  Future<UrlFetchOutput?> fetchUrl({
    required UrlFetchInput input,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<UrlFetchOutput, UrlFetchOutput?>(
        BrowseUrl.fetchUrl,
        data: jsonEncode(input.toJson()),
        decoder: (e) =>
            e is Map<String, dynamic> ? UrlFetchOutput.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
BrowseRepository browseRepository(Ref ref) =>
    BrowseRepository(ref.watch(dioClientKeyProvider));
