// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/migrate_repository/migrate_repository.dart';
import '../../../domain/migrate/migrate_model.dart';

part 'migrate_controller.g.dart';

@riverpod
Future<MigrateInfo?> migrateInfo(MigrateInfoRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result =
      await ref.watch(migrateRepositoryProvider).info(cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
Future<MigrateSourceList?> migrateSourceList(MigrateSourceListRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result =
      await ref.watch(migrateRepositoryProvider).sourceList(cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
class MigrateSourceQuery extends _$MigrateSourceQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
Future<List<MigrateSource>> migrateSourceListFilter(
    MigrateSourceListFilterRef ref) async {
  final query = ref.watch(migrateSourceQueryProvider);
  final data = await ref.watch(migrateSourceListProvider.future);
  if (data?.list?.isNotEmpty != true) {
    return [];
  }
  final list = data!.list!;

  bool applyFilter(MigrateSource source) {
    if (query.isNotBlank == true &&
        source.source?.name?.query(query) != true) {
      return false;
    }
    return true;
  }

  int applySort(MigrateSource m1, MigrateSource m2) {
    return (m1.source?.name ?? "").compareTo(m2.source?.name ?? "");
  }

  return list.where(applyFilter).toList()..sort(applySort);
}

@riverpod
Future<MigrateMangaList?> migrateMangaList(
  MigrateMangaListRef ref, {
  required String sourceId,
}) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(migrateRepositoryProvider)
      .mangaList(sourceId: sourceId, cancelToken: token);
  ref.keepAlive();

  return result;
}

@riverpod
class MigrateMangaQuery extends _$MigrateMangaQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
Future<List<Manga>> migrateMangaListFilter(
  MigrateMangaListFilterRef ref, {
  required String sourceId,
}) async {
  final query = ref.watch(migrateMangaQueryProvider);

  final data =
      await ref.watch(migrateMangaListProvider(sourceId: sourceId).future);
  if (data?.list?.isNotEmpty != true) {
    return [];
  }
  final list = data!.list!;

  bool applyFilter(Manga manga) {
    if (query.isNotBlank == true && manga.title?.query(query) != true) {
      return false;
    }
    return true;
  }

  int applySort(Manga m1, Manga m2) {
    return (m1.title ?? "").compareTo(m2.title ?? "");
  }

  return list.where(applyFilter).toList()..sort(applySort);
}

@riverpod
class MigrateChapterPref extends _$MigrateChapterPref with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.migrateChapterFlag.name,
    initial: DBKeys.migrateChapterFlag.initial,
  );
}

@riverpod
class MigrateCategoryPref extends _$MigrateCategoryPref with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.migrateCategoryFlag.name,
    initial: DBKeys.migrateCategoryFlag.initial,
  );
}

@riverpod
class MigrateTrackingPref extends _$MigrateTrackingPref with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.migrateTrackFlag.name,
    initial: DBKeys.migrateTrackFlag.initial,
  );
}