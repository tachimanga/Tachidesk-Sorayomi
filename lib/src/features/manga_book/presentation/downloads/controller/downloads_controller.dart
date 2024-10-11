// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../data/downloads/downloads_repository.dart';

part 'downloads_controller.g.dart';

@riverpod
class DownloadTaskInParallelPref extends _$DownloadTaskInParallelPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.downloadTaskInParallel.initial,
        key: DBKeys.downloadTaskInParallel.name,
      );
}

@riverpod
class DeleteDownloadAfterReadPref extends _$DeleteDownloadAfterReadPref
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
        ref,
        initial: DBKeys.deleteDownloadAfterRead.initial,
        key: DBKeys.deleteDownloadAfterRead.name,
      );
}

@riverpod
class DeleteDownloadAfterReadTodoList extends _$DeleteDownloadAfterReadTodoList
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
        ref,
        key: DBKeys.deleteDownloadAfterReadTodoList.name,
        initial: DBKeys.deleteDownloadAfterReadTodoList.initial,
      );
}

@riverpod
class DownloadSpeed extends _$DownloadSpeed {
  Timer? timer;
  int speed = 0;
  String? speedString;

  @override
  String build() {
    final pipe = ref.watch(getMagicPipeProvider);
    //log("[debug] build");
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      //log("[debug] update");
      speed = await pipe.invokeMethod("DOWNLOAD:SPEED:GET");
      state = buildString(speed);
    });
    ref.onDispose(() {
      //log("[debug] dispose");
      timer?.cancel();
    });
    return speedString ?? "";
  }

  String buildString(int speed) {
    if (speed < 1024) {
      return '0KB/s';
    } else if (speed >= 1024 && speed < 1024 * 1024) {
      return '${(speed / 1024).toStringAsFixed(0)}KB/s';
    } else if (speed >= 1024 * 1024 && speed < 1024 * 1024 * 1024) {
      return '${(speed / (1024 * 1024)).toStringAsFixed(1)}MB/s';
    } else {
      return '${(speed / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB/s';
    }
  }
}

@riverpod
class DownloadStatus extends _$DownloadStatus {
  Timer? timer;
  bool started = false;
  String? curr;

  @override
  DownloadQueueStatus build() {
    final downloads = ref.watch(downloadsSocketProvider);
    curr = downloads.valueOrNull?.status;
    if (curr == DownloadQueueStatus.started.code) {
      started = true;
    }
    //log("[debug] started:${started} curr:$curr");

    timer?.cancel();
    timer = Timer(const Duration(seconds: 1), () async {
      //log("[debug] check: curr:$curr");
      if (curr == DownloadQueueStatus.stopped.code) {
        started = false;
        state = DownloadQueueStatus.stopped;
      }
    });

    ref.onDispose(() {
      //log("[debug] dispose");
      timer?.cancel();
    });

    return started ? DownloadQueueStatus.started : DownloadQueueStatus.stopped;
  }
}
