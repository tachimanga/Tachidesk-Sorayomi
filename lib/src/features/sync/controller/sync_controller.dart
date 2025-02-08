// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../cloud/data/api3_repository.dart';
import '../../../cloud/domain/api3_model.dart';
import '../../../constants/endpoints.dart';
import '../../../utils/event_util.dart';
import '../../../utils/log.dart';
import '../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../utils/mixin/state_provider_mixin.dart';
import '../../settings/controller/edit_repo_controller.dart';
import '../data/sync_repository.dart';
import '../domain/sync_model.dart';

part 'sync_controller.g.dart';

@riverpod
class SyncRefreshSignal extends _$SyncRefreshSignal {
  String? prev;

  @override
  bool build() {
    final status = ref.watch(syncSocketProvider);
    final curr = status.valueOrNull?.state;
    final counter = status.valueOrNull?.counter;
    final applied =
        (counter?.appliedCount ?? 0) + (counter?.appliedCount2 ?? 0);
    final signal = (prev != SyncState.success.value &&
        curr == SyncState.success.value &&
        applied > 0);
    //log("[SYNC] prev:$prev curr:$curr signal:$signal applied:$applied");
    prev = curr;
    return signal;
  }
}

@riverpod
class SyncSuccessListener extends _$SyncSuccessListener {
  @override
  int build() {
    final needRefresh = ref.watch(syncRefreshSignalProvider);
    log("[SYNC] sync done, needRefresh:$needRefresh");
    if (needRefresh) {
      ref.read(repoControllerProvider.notifier).reloadRepoList();
    }
    return 0;
  }
}

@riverpod
class SyncSocket extends _$SyncSocket {
  @override
  Stream<SyncStatus> build() {
    final pair = ref.watch(syncRepositoryProvider).socketUpdates();
    ref.onDispose(pair.second);
    return pair.first;
  }
}

@riverpod
class SyncWhenAppStartPref extends _$SyncWhenAppStartPref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: "config.syncWhenAppStart",
        initial: true,
      );
}

@riverpod
class SyncWhenAppResumePref extends _$SyncWhenAppResumePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: "config.syncWhenAppResume",
        initial: true,
      );
}

@riverpod
class SyncPollingInterval extends _$SyncPollingInterval
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        key: "config.syncPollingInterval",
        initial: 0,
      );
}

@riverpod
class CloudServerPref extends _$CloudServerPref
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: "config.cloudServer",
        initial: Endpoints.api3host,
      );
}

@riverpod
Future<InfoFetchResult?> syncNoticeInfo(SyncNoticeInfoRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref.watch(api3RepositoryProvider).infoFetch("SYNC_INFO");
  ref.keepAlive();
  return result;
}
