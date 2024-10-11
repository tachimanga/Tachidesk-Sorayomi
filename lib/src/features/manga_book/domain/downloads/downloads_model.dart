// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../downloads_queue/downloads_queue_model.dart';

part 'downloads_model.freezed.dart';
part 'downloads_model.g.dart';

// DownloadStatus
@freezed
class Downloads with _$Downloads {
  factory Downloads({
    List<DownloadsQueue>? queue,
    String? status,
    int? finishCount,
  }) = _Downloads;

  factory Downloads.fromJson(Map<String, dynamic> json) =>
      _$DownloadsFromJson(json);
}
