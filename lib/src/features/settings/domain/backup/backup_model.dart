// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_model.freezed.dart';
part 'backup_model.g.dart';

@freezed
class BackupItem with _$BackupItem {
  factory BackupItem({
    int? backupId,
    String? name,
    int? createAt,
    int? updateAt,
    int? size,
    int? type,
    bool? cloudBackup,
    bool? remoteBackup,
    bool? downloaded,
    double? downloadProgress,
  }) = _BackupItem;

  factory BackupItem.fromJson(Map<String, dynamic> json) =>
      _$BackupItemFromJson(json);
}

@freezed
class BackupList with _$BackupList {
  factory BackupList({
    List<BackupItem>? list,
  }) = _BackupList;

  factory BackupList.fromJson(Map<String, dynamic> json) =>
      _$BackupListFromJson(json);
}

@freezed
class BackupListResult with _$BackupListResult {
  factory BackupListResult({
    bool? succ,
    String? message,
    BackupList? data,
  }) = _BackupListResult;

  factory BackupListResult.fromJson(Map<String, dynamic> json) =>
      _$BackupListResultFromJson(json);
}

@freezed
class BackupResult with _$BackupResult {
  factory BackupResult({
    bool? succ,
    String? message,
  }) = _BackupResult;

  factory BackupResult.fromJson(Map<String, dynamic> json) =>
      _$BackupResultFromJson(json);
}

@freezed
class BackupStatus with _$BackupStatus {
  factory BackupStatus({
    String? state,
    String? message,
    List<String>? codes,
  }) = _BackupStatus;

  factory BackupStatus.fromJson(Map<String, dynamic> json) =>
      _$BackupStatusFromJson(json);
}

enum BackupState {
  init("INIT"),
  running("RUNNING"),
  success("SUCCESS"),
  fail("FAIL");

  final String value;
  const BackupState(
    this.value,
  );
}
