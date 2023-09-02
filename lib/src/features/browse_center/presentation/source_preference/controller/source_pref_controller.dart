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
import '../../../data/source_repository/source_repository.dart';
import '../../../domain/source/source_model.dart';
import '../../../domain/source_pref/source_pref_model.dart';

part 'source_pref_controller.g.dart';

@riverpod
Future<List<SourcePref>?> sourcePrefList(SourcePrefListRef ref, String sourceId) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(sourceRepositoryProvider)
      .getSourcePrefList(sourceId: sourceId, cancelToken: token);
  ref.keepAlive();
  return result;
}

