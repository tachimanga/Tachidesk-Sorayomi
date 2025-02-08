// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/manga/manga_model.dart';

part 'history_controller.g.dart';

@riverpod
Future<List<Manga>?> historyList(HistoryListRef ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(mangaBookRepositoryProvider)
      .getMangasFromHistory(cancelToken: token);
  ref.keepAlive();
  return result;
}

@riverpod
class HistoryMangaQuery extends _$HistoryMangaQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
AsyncValue<List<Manga>?> historyListFilter(HistoryListFilterRef ref) {
  final query = ref.watch(historyMangaQueryProvider);
  final value = ref.watch(historyListProvider);
  final list = value.valueOrNull;

  bool applyFilter(Manga manga) {
    if (query.isNotBlank == true && manga.title?.query(query) != true) {
      return false;
    }
    return true;
  }

  final filtered = list?.where(applyFilter).toList();
  return value.copyWithData((p0) => filtered);
}
