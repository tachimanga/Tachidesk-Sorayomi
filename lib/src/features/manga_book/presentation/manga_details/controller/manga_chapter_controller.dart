// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/log.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/manga/manga_model.dart';
import 'manga_details_controller.dart';

part 'manga_chapter_controller.g.dart';

@riverpod
class MangaChapterSortWithMangaId extends _$MangaChapterSortWithMangaId {
  Timer? debounce;

  @override
  ChapterSort? build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalValue = ref.watch(mangaChapterSortProvider);
    final effectValue = manga?.meta?.chapterSort ?? globalValue;

    log("[MangaMeta] manga:$mangaId, global:$globalValue manga:${manga?.meta?.chapterSort} effect:$effectValue");
    return effectValue;
  }

  void update(ChapterSort? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final globalValue = ref.read(mangaChapterSortProvider);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.chapterSort.key,
                value: value == globalValue ? null : value?.name,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}

@riverpod
class MangaChapterSortDirectionWithMangaId
    extends _$MangaChapterSortDirectionWithMangaId {
  Timer? debounce;

  @override
  bool? build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalValue = ref.watch(mangaChapterSortDirectionProvider);
    final effectValue = manga?.meta?.chapterSortDirection ?? globalValue;

    log("[MangaMeta] manga:$mangaId, global:$globalValue manga:${manga?.meta?.chapterSortDirection} effect:$effectValue");
    return effectValue;
  }

  void update(bool? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final globalValue = ref.read(mangaChapterSortDirectionProvider);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.chapterSortDirection.key,
                value: value == globalValue ? null : value,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}

@riverpod
class MangaChapterFilterDownloadedWithMangaId
    extends _$MangaChapterFilterDownloadedWithMangaId {
  Timer? debounce;

  @override
  bool? build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalValue = ref.watch(mangaChapterFilterDownloadedProvider);
    final triState = manga?.meta?.chapterFilterDownloaded;
    final effectValue = triState == null ? globalValue : triState.toBool();

    log("[MangaMeta] Downloaded manga:$mangaId, globalValue:$globalValue triState:$triState effectValue:$effectValue");
    return effectValue;
  }

  void update(bool? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final globalValue = ref.read(mangaChapterFilterDownloadedProvider);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.chapterFilterDownloaded.key,
                value:
                    value == globalValue ? null : TriState.fromBool(value).name,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}

@riverpod
class MangaChapterFilterUnreadWithMangaId
    extends _$MangaChapterFilterUnreadWithMangaId {
  Timer? debounce;

  @override
  bool? build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalValue = ref.watch(mangaChapterFilterUnreadProvider);
    final triState = manga?.meta?.chapterFilterUnread;
    final effectValue = triState == null ? globalValue : triState.toBool();

    log("[MangaMeta] Unread: manga:$mangaId, globalValue:$globalValue triState:$triState effectValue:$effectValue");
    return effectValue;
  }

  void update(bool? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final globalValue = ref.read(mangaChapterFilterUnreadProvider);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.chapterFilterUnread.key,
                value:
                    value == globalValue ? null : TriState.fromBool(value).name,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}

@riverpod
class MangaChapterFilterBookmarkedWithMangaId
    extends _$MangaChapterFilterBookmarkedWithMangaId {
  Timer? debounce;

  @override
  bool? build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalValue = ref.watch(mangaChapterFilterBookmarkedProvider);
    final triState = manga?.meta?.chapterFilterBookmarked;
    final effectValue = triState == null ? globalValue : triState.toBool();

    log("[MangaMeta] Bookmarked manga:$mangaId, globalValue:$globalValue triState:$triState effectValue:$effectValue");
    return effectValue;
  }

  void update(bool? value) {
    state = value;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kInstantDuration,
      () {
        AsyncValue.guard(() async {
          final globalValue = ref.read(mangaChapterFilterBookmarkedProvider);
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.chapterFilterBookmarked.key,
                value:
                    value == globalValue ? null : TriState.fromBool(value).name,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}
