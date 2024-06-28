// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/endpoints.dart';
import '../../../constants/enum.dart';
import '../../extensions/custom_extensions.dart';

part 'network_module.g.dart';

// Must be top-level function
_parseAndDecode(String response) => jsonDecode(response);

parseJson(String text) => compute(_parseAndDecode, text);

class DioNetworkModule {
  Dio provideDio({
    required String baseUrl,
  }) {
    final dio = Dio();
    (dio.transformer as BackgroundTransformer).jsonDecodeCallback = parseJson;

    dio
      ..options.baseUrl = Endpoints.baseApi(baseUrl: baseUrl)
      ..options.connectTimeout = Endpoints.connectionTimeout
      ..options.receiveTimeout = Endpoints.receiveTimeout
      ..options.contentType = Headers.jsonContentType
      ..options.headers = {'Content-Type': 'application/json; charset=utf-8'};
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        responseBody: true,
        requestBody: true,
        logPrint: (e) => debugPrint(e.toString()),
      ));
    }

    return dio;
  }
}

@riverpod
DioNetworkModule networkModule(ref) => DioNetworkModule();
