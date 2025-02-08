// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/mixin/state_provider_mixin.dart';
import '../data/account_repository.dart';
import '../domain/account_model.dart';

part 'account_controller.g.dart';

@riverpod
Future<CloudUserInfo?> userInfo(UserInfoRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result =
      await ref.watch(accountRepositoryProvider).userInfo(cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
class UserLoginSignal extends _$UserLoginSignal
    with StateProviderMixin<int?> {
  @override
  int? build() => 0;
}
