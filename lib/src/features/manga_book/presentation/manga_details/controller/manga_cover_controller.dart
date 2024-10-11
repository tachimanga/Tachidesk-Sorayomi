// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../utils/cover/cover_cache_manager.dart';

part 'manga_cover_controller.g.dart';

@riverpod
Future<bool> mangaCustomCoverExist(MangaCustomCoverExistRef ref, {
required String mangaId,
}) async {
  final cover = await CoverCacheManager().getCustomCover(mangaId);
  return cover != null;
}