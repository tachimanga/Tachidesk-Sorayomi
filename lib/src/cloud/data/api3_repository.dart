// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:ui';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/about/presentation/about/controllers/about_controller.dart';
import '../../global_providers/global_providers.dart';
import '../../global_providers/locale_providers.dart';
import '../../utils/storage/dio/dio_client.dart';
import '../controller/api3_providers.dart';
import '../domain/api3_model.dart';

part 'api3_repository.g.dart';

class Api3Repository {
  final DioClient dioClient;
  final PackageInfo packageInfo;
  final Locale appLocale;

  Api3Repository({
    required this.dioClient,
    required this.packageInfo,
    required this.appLocale,
  });

  Future<InfoFetchResult?> infoFetch(String dataKey) async {
    final result = (await dioClient.post<InfoFetchResult, InfoFetchResult?>(
      "/api/info/fetch",
      data: json.encode({
        "dataKey": dataKey,
        "callerInfo": buildCallerInfo(),
      }),
      decoder: (e) =>
          e is Map<String, dynamic> ? InfoFetchResult.fromJson(e) : null,
    ))
        .data;
    return result;
  }

  CallerInfo buildCallerInfo() {
    return CallerInfo(
      clientTimestamp: DateTime.now().millisecondsSinceEpoch,
      version: packageInfo.version,
      build: packageInfo.buildNumber,
      bundleId: packageInfo.packageName,
      // String? deviceId,
      locale: appLocale.toString(),
    );
  }
}

@riverpod
Api3Repository api3Repository(ref) => Api3Repository(
      dioClient: ref.watch(dioClientApi3Provider),
      packageInfo: ref.watch(packageInfoProvider),
      appLocale: ref.watch(appLocaleProvider),
    );
