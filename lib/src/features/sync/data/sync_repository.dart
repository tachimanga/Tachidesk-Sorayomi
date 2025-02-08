// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../constants/endpoints.dart';
import '../../../global_providers/global_providers.dart';
import '../../../utils/classes/pair/pair_model.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/storage/dio/dio_client.dart';
import '../domain/sync_model.dart';

part 'sync_repository.g.dart';

class SyncRepository {
  final DioClient dioClient;

  SyncRepository(this.dioClient);

  Future<void> enableSync({
    CancelToken? cancelToken,
  }) =>
      dioClient.get(SyncUrl.enableSync, cancelToken: cancelToken);

  Future<void> disableSync({
    CancelToken? cancelToken,
  }) =>
      dioClient.get(SyncUrl.disableSync, cancelToken: cancelToken);

  Future<void> syncNow({
    CancelToken? cancelToken,
  }) =>
      dioClient.get(SyncUrl.syncNow, cancelToken: cancelToken);

  Future<void> syncNowIfEnable({
    CancelToken? cancelToken,
  }) =>
      dioClient.get(SyncUrl.syncNowIfEnable, cancelToken: cancelToken);

  Pair<Stream<SyncStatus>, AsyncCallback> socketUpdates() {
    final url = (dioClient.dio.options.baseUrl.toWebSocket!);
    final channel = WebSocketChannel.connect(Uri.parse(url + SyncUrl.ws));
    return Pair<Stream<SyncStatus>, AsyncCallback>(
      first: channel.stream
          .throttle(const Duration(milliseconds: 300), trailing: true)
          .asyncMap<SyncStatus>((event) => compute<String, SyncStatus>(
              (s) => SyncStatus.fromJson(json.decode(s)), event)),
      second: channel.sink.close,
    );
  }
}

@riverpod
SyncRepository syncRepository(SyncRepositoryRef ref) =>
    SyncRepository(ref.watch(dioClientKeyProvider));
