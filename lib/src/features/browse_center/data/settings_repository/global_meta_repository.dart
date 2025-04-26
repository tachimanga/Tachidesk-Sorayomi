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
import '../../domain/settings/global_meta_model.dart';

part 'global_meta_repository.g.dart';

class GlobalMetaRepository {
  final DioClient dioClient;

  GlobalMetaRepository({
    required this.dioClient,
  });

  Future<GlobalMeta?> queryMeta(String key) async {
    final result = (await dioClient.post<GlobalMeta, GlobalMeta?>(
      GlobalMetaUrl.query,
      data: jsonEncode({"key": key}),
      decoder: (e) => e is Map<String, dynamic> ? GlobalMeta.fromJson(e) : null,
    ))
        .data;
    return result;
  }

  Future<void> updateMeta(String key, String value) => dioClient.post(
        GlobalMetaUrl.update,
        data: jsonEncode({"key": key, "value": value}),
      );
}

@riverpod
GlobalMetaRepository globalMetaRepository(ref) => GlobalMetaRepository(
      dioClient: ref.watch(dioClientKeyProvider),
    );
