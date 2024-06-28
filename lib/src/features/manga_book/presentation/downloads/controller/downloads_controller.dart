// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

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