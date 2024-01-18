// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/endpoints.dart';
import '../../../../global_providers/global_providers.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/storage/dio/dio_client.dart';
import '../../domain/extension/extension_model.dart';

part 'extension_repository.g.dart';

class ExtensionRepository {
  final DioClient dioClient;

  ExtensionRepository(this.dioClient);

  Future<void> installExtensionFile(
    BuildContext context, {
    PlatformFile? file,
    CancelToken? cancelToken,
  }) async {
    if ((file?.path).isBlank) {
      throw context.l10n!.errorFilePick;
    }
    if (!(file!.name.endsWith('.apk'))) {
      throw context.l10n!.errorFilePickUnknownExtension(".apk");
    }
    return (file.path).isNotBlank
        ? (await dioClient.post(
            ExtensionUrl.installFile,
            data: FormData.fromMap({
              'file': MultipartFile.fromFileSync(
                file.path!,
                filename: file.name,
              )
            }),
            cancelToken: cancelToken,
          ))
            .data
        : null;
  }

  Future<void> installExtension(
    int extensionId, {
    CancelToken? cancelToken,
  }) =>
      dioClient.get(
        ExtensionUrl.installPkg(extensionId),
        cancelToken: cancelToken,
      );

  Future<void> uninstallExtension(
    int extensionId, {
    CancelToken? cancelToken,
  }) =>
      dioClient.get(
        ExtensionUrl.uninstallPkg(extensionId),
        cancelToken: cancelToken,
      );

  Future<void> updateExtension(
    int extensionId, {
    CancelToken? cancelToken,
  }) =>
      dioClient.get(
        ExtensionUrl.updatePkg(extensionId),
        cancelToken: cancelToken,
      );

  Future<List<Extension>?> getExtensionList(String repoUrl,
          {CancelToken? cancelToken}) async =>
      (await dioClient.get<List<Extension>, Extension>(
        ExtensionUrl.list,
        queryParameters: {"repoUrl": repoUrl},
        decoder: (e) =>
            e is Map<String, dynamic> ? Extension.fromJson(e) : Extension(),
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
ExtensionRepository extensionRepository(ExtensionRepositoryRef ref) =>
    ExtensionRepository(ref.watch(dioClientKeyProvider));
