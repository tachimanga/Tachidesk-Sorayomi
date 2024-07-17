// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_blacklist_config.freezed.dart';
part 'remote_blacklist_config.g.dart';

@freezed
class BlacklistConfig with _$BlacklistConfig {
  factory BlacklistConfig({
    List<String>? blackRepoUrlList,
    List<String>? blackApkNameList,
    List<String>? blackApkHashList,
    List<String>? blackMangaUrlList,
  }) = _BlacklistConfig;

  factory BlacklistConfig.fromJson(Map<String, dynamic> json) => _$BlacklistConfigFromJson(json);
}