// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../manga/manga_model.dart';

part 'update_status_model.freezed.dart';
part 'update_status_model.g.dart';

@freezed
class UpdateStatus with _$UpdateStatus {
  UpdateStatus._();
  factory UpdateStatus({
    UpdateStatusMap? statusMap,
    bool? running,
    int? numberOfJobs,
    int? completeTimestamp,
  }) = _UpdateStatus;

  int get total => numberOfJobs ?? 0;

  int get updateChecked => (statusMap?.completed?.length ?? 0) + (statusMap?.failed?.length ?? 0);

  bool get isUpdateCompleted => total == updateChecked;

  bool get showUpdateStatus => (total).isGreaterThan(0) && !(isUpdateCompleted);

  factory UpdateStatus.fromJson(Map<String, dynamic> json) =>
      _$UpdateStatusFromJson(json);
}

@freezed
class UpdateStatusMap with _$UpdateStatusMap {
  factory UpdateStatusMap({
    @JsonKey(name: "PENDING") List<Manga>? pending,
    @JsonKey(name: "RUNNING") List<Manga>? running,
    @JsonKey(name: "COMPLETE") List<Manga>? completed,
    @JsonKey(name: "FAILED") List<Manga>? failed,
  }) = _UpdateStatusMap;

  factory UpdateStatusMap.fromJson(Map<String, dynamic> json) =>
      _$UpdateStatusMapFromJson(json);
}
