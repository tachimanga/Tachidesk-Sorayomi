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

