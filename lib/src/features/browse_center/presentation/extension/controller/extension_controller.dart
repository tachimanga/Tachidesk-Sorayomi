// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

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
import '../../../../settings/data/repo/repo_repository.dart';
import '../../../../settings/presentation/browse/widgets/repo_setting/repo_url_tile.dart';
import '../../../../settings/presentation/browse/widgets/show_nsfw_switch/show_nsfw_switch.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../../../domain/extension/extension_model.dart';
import '../../../domain/extension/extension_tag.dart';

part 'extension_controller.g.dart';

@riverpod
Future<List<Extension>?> extension(ExtensionRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);

  final repo = ref.watch(repoParamProvider);
  final result = await ref
      .watch(extensionRepositoryProvider)
      .getExtensionList(repo, cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
Future<int?> extensionUpdate(ExtensionUpdateRef ref) async {
  final extensionMapData = ref.watch(extensionMapFilteredProvider);
  final extensionMap = {...?extensionMapData.valueOrNull};
  final count = extensionMap["update"]?.length ?? 0;
  ref.keepAlive();
  return count;
}

@riverpod
String repoParam(RepoParamRef ref) {
  return "";
}

@riverpod
bool emptyRepo(EmptyRepoRef ref) {
  final magic = ref.watch(getMagicProvider);
  final repo = ref.watch(repoParamProvider);

  final repoList = ref.watch(repoListWithCacheProvider);
  if (repoList.valueOrNull?.isNotEmpty == true) {
    return false;
  }

  return magic.b4 && repo == "DEFAULT";
}

@riverpod
Future<Map<String, ExtensionTag>> extensionTag(ExtensionTagRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);

  final repo = ref.watch(repoParamProvider);
  final userDefaults = ref.read(sharedPreferencesProvider);

  ExtensionTagData? result = ExtensionTagData();
  if (repo != "DEFAULT") {
    try {
      final s = userDefaults.getString("config.extensionTagJson");
      try {
        result = ExtensionTagData.fromJson(json.decode(s ?? "{}"));
      } catch (e) {
        log("extensionTagJson parse error:$e");
      }
      log("extensionTagJson:$result, json:$s");
    } catch (e) {
      log("load extension tag err:$e");
    }
  }

  final extensionTagMap = <String, ExtensionTag>{};
  result?.list?.forEach((tag) {
    extensionTagMap[tag.pkg ?? ""] = tag;
  });

  ref.keepAlive();
  return extensionTagMap;
}

@riverpod
AsyncValue<Map<String, List<Extension>>> extensionMap(ExtensionMapRef ref) {
  final extensionMap = <String, List<Extension>>{};
  final extensionListData = ref.watch(extensionProvider);
  final extensionListDraft = [...?extensionListData.valueOrNull];
  final extensionList = <Extension>[];
  final extensionTagMapValue = ref.watch(extensionTagProvider);
  final extensionTagMap = extensionTagMapValue.valueOrNull ?? {};

  for (final e in extensionListDraft) {
    final extensionTag = extensionTagMap[e.pkgName];
    if (extensionTag == null) {
      extensionList.add(e);
    } else {
      if (extensionTag.down != true) {
        final ee = e.copyWith(
          name: (e.name ?? "") + (extensionTag.suffix ?? ""),
          tagList: extensionTag.tagList,
          isNsfw: extensionTag.top == true ? false : e.isNsfw
        );
        extensionList.add(ee);
      }
    }
  }

  var showNsfw = false;
  var userPref = ref.watch(showNSFWProvider);
  if (userPref != null) {
    showNsfw = userPref;
  }

  for (final e in extensionList) {
    if (!showNsfw && (e.isNsfw.ifNull()) && e.installed != true) continue;
    if (e.installed.ifNull()) {
      if (e.hasUpdate.ifNull()) {
        extensionMap.update(
          "update",
          (value) => [...value, e],
          ifAbsent: () => [e],
        );
      } else {
        extensionMap.update(
          "installed",
          (value) => [...value, e],
          ifAbsent: () => [e],
        );
      }
    } else {
      final extensionTag = extensionTagMap[e.pkgName];
      extensionMap.update(
        e.lang?.code?.toLowerCase() ?? "other",
        (value) => extensionTag?.top == true ? [e, ...value] : [...value, e],
        ifAbsent: () => [e],
      );
    }
  }
  return extensionListData.copyWithData((p0) => extensionMap);
}

@riverpod
List<String> extensionFilterLangList(ExtensionFilterLangListRef ref) {
  return [
    ...?(ref.watch(extensionMapProvider).valueOrNull
          ?..remove("installed")
          ..remove("update"))
        ?.keys
  ]..sort();
}

@riverpod
class ExtensionLanguageFilter extends _$ExtensionLanguageFilter
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
        ref,
        key: DBKeys.extensionLanguageFilter.name,
        initial: DBKeys.extensionLanguageFilter.initial +
            ref.watch(sysPreferLocalesProvider),
      );
}

@riverpod
AsyncValue<Map<String, List<Extension>>> extensionMapFiltered(
    ExtensionMapFilteredRef ref) {
  final extensionMapFiltered = <String, List<Extension>>{};
  final extensionMapData = ref.watch(extensionMapProvider);
  final extensionMap = {...?extensionMapData.valueOrNull};
  final enabledLangList = [...?ref.watch(extensionLanguageFilterProvider)];
  for (final e in enabledLangList) {
    if (extensionMap.containsKey(e)) extensionMapFiltered[e] = extensionMap[e]!;
  }
  return extensionMapData.copyWithData((p0) => extensionMapFiltered);
}

@riverpod
AsyncValue<Map<String, List<Extension>>> extensionMapFilteredAndQueried(
  ExtensionMapFilteredAndQueriedRef ref,
) {
  final extensionMapData = ref.watch(extensionMapFilteredProvider);
  final extensionMap = {...?extensionMapData.valueOrNull};
  final query = ref.watch(extensionQueryProvider);
  if (query.isBlank) return extensionMapData;
  return extensionMapData.copyWithData(
    (e) => extensionMap.map<String, List<Extension>>(
      (key, value) => MapEntry(
        key,
        value.where((element) => element.name.query(query)).toList(),
      ),
    ),
  );
}

@riverpod
AsyncValue<Map<String, List<Extension>>>
    extensionMapFilteredAndQueriedAndRepoId(
  ExtensionMapFilteredAndQueriedRef ref, {
  required int repoId,
}) {
  final extensionMapData = ref.watch(extensionMapFilteredProvider);
  final extensionMap = {...?extensionMapData.valueOrNull};
  final query = ref.watch(extensionQueryProvider);
  return extensionMapData.copyWithData(
    (e) => extensionMap.map<String, List<Extension>>(
      (key, value) => MapEntry(
        key,
        value
            .where((element) =>
                element.repoId == repoId &&
                (query.isBlank || element.name.query(query)))
            .toList(),
      ),
    ),
  );
}

@riverpod
class ExtensionQuery extends _$ExtensionQuery with StateProviderMixin<String?> {
  @override
  String? build() => null;
}
