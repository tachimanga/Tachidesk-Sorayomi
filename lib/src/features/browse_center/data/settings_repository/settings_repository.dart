// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/endpoints.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/storage/dio/dio_client.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  final DioClient dioClient;

  SettingsRepository({
    required this.dioClient,
  });

  Future<void> uploadCookies({dynamic json}) =>
      dioClient.post(SettingsUrl.uploadCookies, data: json);

  Future<void> clearCookies() =>
      dioClient.get(SettingsUrl.clearCookies);
}

@riverpod
SettingsRepository settingsRepository(ref) => SettingsRepository(
  dioClient: ref.watch(dioClientKeyProvider),
);
