// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/urls.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../global_providers/locale_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../settings/controller/edit_repo_controller.dart';
import '../../../../settings/domain/repo/repo_model.dart';
import '../../../../settings/presentation/browse/widgets/repo_setting/repo_url_tile.dart';
import '../../../../settings/presentation/browse/widgets/show_nsfw_switch/show_nsfw_switch.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/extension/extension_info_model.dart';
import '../../../domain/extension/extension_model.dart';
import '../../../domain/extension/extension_tag.dart';
import '../../../domain/source/source_model.dart';
import '../../source/controller/source_controller.dart';
import 'extension_controller.dart';

part 'extension_info_controller.g.dart';


@riverpod
Future<List<Source>?> sourceListNoCache(SourceListNoCacheRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(sourceRepositoryProvider)
      .getSourceList(cancelToken: token);
  return result;
}

@riverpod
AsyncValue<ExtensionInfo> extensionInfo(
  ExtensionInfoRef ref, {
  int? extensionId,
}) {
  final extensionListData = ref.watch(extensionProvider);
  final sourceListData = ref.watch(sourceListNoCacheProvider);

  final extension = extensionListData.valueOrNull
      ?.where((e) => e.extensionId == extensionId)
      .firstOrNull;
  final sources = sourceListData.valueOrNull
      ?.where((e) => e.extPkgName == extension?.pkgName)
      .toList();

  final repoList = ref.watch(repoControllerProvider);
  final repo = repoList.valueOrNull?.where((e) => e.id == extension?.repoId).firstOrNull;

  final changelogUrl = getChangelogUrl(extension, repo);
  final readmeUrl = getReadmeUrl(extension, repo);

  return sourceListData.copyWithData((p0) => ExtensionInfo(
      extension: extension,
      sources: sources,
      changelogUrl: changelogUrl,
      readmeUrl: readmeUrl));
}

const URL_EXTENSION_COMMITS = "/commits/main";
const URL_EXTENSION_BLOB = "/blob/main";

String createUrl(String? baseUrl, String url, String pkgName, String? pkgFactory, {String path = ""}) {
  var finalBaseUrl = "";
  if (baseUrl != null) {
    RegExp regex = RegExp(r"https://.*?github.*?/(.*?)/(.*?)/");
    Match? match = regex.firstMatch(baseUrl);
    if (match != null) {
      String username = match.group(1)!;
      String repo = match.group(2)!;
      finalBaseUrl = "https://github.com/$username/$repo";
    }
  }
  if (pkgFactory?.isNotEmpty == true) {
    if (path.isEmpty) {
      return "$finalBaseUrl$url/multisrc/src/main/java/eu/kanade/tachiyomi/multisrc/$pkgFactory";
    } else {
      final parts = pkgName.split('.');
      String package = parts.isNotEmpty ? parts.last : "";
      return "$finalBaseUrl$url/multisrc/overrides/$pkgFactory/$package$path";
    }
  } else {
    return "$finalBaseUrl$url/src/${pkgName.replaceAll('.', '/')}$path";
  }
}

String getChangelogUrl(Extension? extension, Repo? repo) {
  if (extension == null || extension.pkgName?.isEmpty == true) {
    return "";
  }
  final pkgName = extension.pkgName!.replaceAll("eu.kanade.tachiyomi.extension.", "");
  if (extension.hasReadme == true) {
    return createUrl(repo?.baseUrl, URL_EXTENSION_BLOB, pkgName, extension.pkgFactory, path: "/CHANGELOG.md");
  }
  // Falling back on GitHub commit history because there is no explicit changelog in extension
  return createUrl(repo?.baseUrl, URL_EXTENSION_COMMITS, pkgName, extension.pkgFactory);
}

String getReadmeUrl(Extension? extension, Repo? repo) {
  if (extension == null || extension.pkgName?.isEmpty == true) {
    return AppUrls.extensionHelp.url;
  }

  if (extension.hasReadme == true) {
    final pkgName = extension.pkgName!.replaceAll("eu.kanade.tachiyomi.extension.", "");
    return createUrl(repo?.baseUrl, URL_EXTENSION_BLOB, pkgName, extension.pkgFactory, path: "/CHANGELOG.md");
  }

  return "${AppUrls.extensionHelp.url}?pkg=${extension.pkgName}";
}
