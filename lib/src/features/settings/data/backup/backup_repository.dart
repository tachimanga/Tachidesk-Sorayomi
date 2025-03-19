// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../constants/endpoints.dart';
import '../../../../global_providers/global_providers.dart';

import '../../../../utils/classes/pair/pair_model.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/storage/dio/dio_client.dart';
import '../../domain/backup/backup_model.dart';

part 'backup_repository.g.dart';

class ProtoBackupRepository {
  const ProtoBackupRepository(this.dioClient);

  final DioClient dioClient;

  Future<ProtoImportResult?> restoreBackup(
      BuildContext context, PlatformFile? file, String defaultRepoUrl) async {
    if ((file?.name).isBlank ||
        (kIsWeb && (file?.bytes).isBlank ||
            (!kIsWeb && (file?.path).isBlank))) {
      throw context.l10n!.errorFilePick;
    }
    if (!(file!.name.endsWith('.gz') || file.name.endsWith('.tachibk'))) {
      throw context.l10n!.errorFilePickUnknownType(".proto.gz or .tachibk");
    }
    return (await dioClient.post<ProtoImportResult, ProtoImportResult?>(
      ProtoBackupUrl.import,
      data: FormData.fromMap({
        'defaultRepoUrl': defaultRepoUrl,
        'backup.proto.gz': kIsWeb
            ? MultipartFile.fromBytes(
                file!.bytes!,
                filename: "backup.proto.gz",
              )
            : MultipartFile.fromFileSync(
                file!.path!,
                filename: "backup.proto.gz",
              )
      }),
      decoder: (e) =>
          e is Map<String, dynamic> ? ProtoImportResult.fromJson(e) : null,
    ))
        .data;
  }

  Pair<Stream<BackupStatus>, AsyncCallback> socketUpdates() {
    final url = (dioClient.dio.options.baseUrl.toWebSocket!);
    final channel =
        WebSocketChannel.connect(Uri.parse(url + ProtoBackupUrl.importWs));
    return Pair<Stream<BackupStatus>, AsyncCallback>(
      first: channel.stream
          .throttle(const Duration(milliseconds: 300), trailing: true)
          .asyncMap<BackupStatus>((event) => compute<String, BackupStatus>(
              (s) => BackupStatus.fromJson(json.decode(s)), event)),
      second: channel.sink.close,
    );
  }

  Future<ProtoBackupResult?> createProtoBackup({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post<ProtoBackupResult, ProtoBackupResult?>(
        ProtoBackupUrl.export,
        data: jsonEncode({"dummy": ""}),
        decoder: (e) =>
            e is Map<String, dynamic> ? ProtoBackupResult.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
ProtoBackupRepository backupRepository(BackupRepositoryRef ref) =>
    ProtoBackupRepository(ref.watch(dioClientKeyProvider));
