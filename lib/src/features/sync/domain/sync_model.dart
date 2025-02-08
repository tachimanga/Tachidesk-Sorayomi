// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_model.freezed.dart';
part 'sync_model.g.dart';

@freezed
class SyncStatus with _$SyncStatus {
  factory SyncStatus({
    String? state,
    String? step,
    String? message,
    String? code,
    SyncExtraInfo? extraInfo,
    SyncCounter? counter,
    int? lastSyncAt,
    bool? enable,
    bool? enableBefore,
  }) = _SyncStatus;

  factory SyncStatus.fromJson(Map<String, dynamic> json) =>
      _$SyncStatusFromJson(json);
}

@freezed
class SyncCounter with _$SyncCounter {
  factory SyncCounter({
    int? downloadTotalCount,
    int? downloadedCount,
    int? appliedCount,
    int? uploadTotalCount,
    int? uploadedCount,
    int? downloadTotalCount2,
    int? downloadedCount2,
    int? appliedCount2,
  }) = _SyncCounter;

  factory SyncCounter.fromJson(Map<String, dynamic> json) =>
      _$SyncCounterFromJson(json);
}

extension SyncCounterExtensions on SyncCounter? {
  String toCounterString() {
    final downloaded =
        (this?.downloadedCount ?? 0) + (this?.downloadedCount2 ?? 0);
    final downloadTotal =
        (this?.downloadTotalCount ?? 0) + (this?.downloadTotalCount2 ?? 0);

    final applied = (this?.appliedCount ?? 0) + (this?.appliedCount2 ?? 0);

    final uploaded = this?.uploadedCount ?? 0;
    final uploadTotal = this?.uploadTotalCount ?? 0;

    final finish = (downloaded + applied) / 2;

    // return "${toProgressInt()}% ↓$downloaded/$downloadTotal →$applied/$downloadTotal ↑$uploaded/$uploadTotal";
    return "↓${finish.ceil()}/$downloadTotal ↑$uploaded/$uploadTotal";
  }

  int toProgressInt() {
    int divide(int percent, int? a, int? b) {
      if (a == null || b == null) {
        return 0;
      }
      if (b == 0) {
        return percent;
      }
      return (1.0 * a / b * percent).floor();
    }

    final a = divide(20, this?.downloadedCount, this!.downloadTotalCount);
    final b = divide(50, this?.appliedCount, this!.downloadTotalCount);
    final c = divide(29, this?.uploadedCount, this!.uploadTotalCount);
    final d = divide(
        1,
        (this?.downloadedCount2 ?? 0) + (this?.appliedCount2 ?? 0),
        this!.downloadTotalCount2 != null
            ? this!.downloadTotalCount2! * 2
            : null);
    return min(a + b + c + d, 100);
  }
}

@freezed
class SyncExtraInfo with _$SyncExtraInfo {
  factory SyncExtraInfo({
    int? serverTime,
    int? deviceTime,
    int? maxDiffSeconds,
  }) = _SyncExtraInfo;

  factory SyncExtraInfo.fromJson(Map<String, dynamic> json) =>
      _$SyncExtraInfoFromJson(json);
}

enum SyncState {
  init("INIT"),
  running("RUNNING"),
  success("SUCCESS"),
  fail("FAIL");

  final String value;
  const SyncState(
    this.value,
  );
}

enum SyncStep {
  download("DOWNLOAD"),
  upload("UPLOAD"),
  download2("DOWNLOAD_AGAIN");

  final String value;
  const SyncStep(
    this.value,
  );
}
