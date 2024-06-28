// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'repo_model.freezed.dart';
part 'repo_model.g.dart';

@freezed
class Repo with _$Repo {
  factory Repo({
    int? id,
    int? type,
    String? name,
    String? metaUrl,
    String? baseUrl,
    String? homePageUrl,
  }) = _Repo;

  factory Repo.fromJson(Map<String, dynamic> json) =>
      _$RepoFromJson(json);
}

@freezed
class AddRepoParam with _$AddRepoParam {
  factory AddRepoParam({
    String? repoName,
    String? metaUrl,
  }) = _AddRepoParam;

  factory AddRepoParam.fromJson(Map<String, dynamic> json) =>
      _$AddRepoParamFromJson(json);
}

@freezed
class UpdateByMetaUrlParam with _$UpdateByMetaUrlParam {
  factory UpdateByMetaUrlParam({
    String? metaUrl,
    String? targetMetaUrl,
  }) = _UpdateByMetaUrlParam;

  factory UpdateByMetaUrlParam.fromJson(Map<String, dynamic> json) =>
      _$UpdateByMetaUrlParamFromJson(json);
}

@freezed
class UrlSchemeAddRepo with _$UrlSchemeAddRepo {
  factory UrlSchemeAddRepo({
    String? repoName,
    String? baseUrl,
    String? metaUrl,
  }) = _UrlSchemeAddRepo;

  factory UrlSchemeAddRepo.fromJson(Map<String, dynamic> json) =>
      _$UrlSchemeAddRepoFromJson(json);
}