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
import '../domain/account_model.dart';

part 'account_repository.g.dart';

class AccountRepository {
  final DioClient dioClient;

  AccountRepository(this.dioClient);

  Future<CloudUserInfo?> userInfo({
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.get<CloudUserInfo, CloudUserInfo?>(
        UserUrl.info,
        decoder: (e) =>
            e is Map<String, dynamic> ? CloudUserInfo.fromJson(e) : null,
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> register({
    required UserRegisterInput param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        UserUrl.register,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> login({
    required UserLoginInput param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        UserUrl.login,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> thirdLogin({
    required ThirdLoginInput param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        UserUrl.thirdLogin,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> logout({
    required UserLogoutInput param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        UserUrl.logout,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;

  Future<void> delete({
    required UserDeleteInput param,
    CancelToken? cancelToken,
  }) async =>
      (await dioClient.post(
        UserUrl.delete,
        data: jsonEncode(param.toJson()),
        cancelToken: cancelToken,
      ))
          .data;
}

@riverpod
AccountRepository accountRepository(AccountRepositoryRef ref) =>
    AccountRepository(ref.watch(dioClientKeyProvider));
