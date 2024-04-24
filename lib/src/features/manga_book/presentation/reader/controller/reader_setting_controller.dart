import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/manga/manga_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';

part 'reader_setting_controller.g.dart';

@riverpod
class ReaderPaddingKey extends _$ReaderPaddingKey
    with SharedPreferenceClientMixin<double> {
  @override
  double? build() => initialize(
        ref,
        initial: DBKeys.readerPadding.initial,
        key: DBKeys.readerPadding.name,
      );
}

@riverpod
class ReaderPaddingLandscapeKey extends _$ReaderPaddingLandscapeKey
    with SharedPreferenceClientMixin<double> {
  @override
  double? build() => initialize(
        ref,
        initial: DBKeys.readerPaddingLandscape.initial,
        key: DBKeys.readerPaddingLandscape.name,
      );
}

@riverpod
class ReaderPaddingWithMangaId extends _$ReaderPaddingWithMangaId {
  @override
  double build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final double localMangaReaderPadding =
        ref.watch(readerPaddingKeyProvider) ?? DBKeys.readerPadding.initial;
    if (manga == null) {
      return localMangaReaderPadding;
    }

    return manga.meta?.readerPadding ?? localMangaReaderPadding;
  }

  void update(double p) {
    ref.keepAlive();
    state = p;
  }
}

@riverpod
class ReaderPaddingLandscapeWithMangaId
    extends _$ReaderPaddingLandscapeWithMangaId {
  @override
  double build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final double localMangaReaderPadding =
        ref.watch(readerPaddingKeyProvider) ?? DBKeys.readerPadding.initial;
    if (manga == null) {
      return localMangaReaderPadding;
    }

    return manga.meta?.readerPaddingLandscape ?? localMangaReaderPadding;
  }

  void update(double p) {
    ref.keepAlive();
    state = p;
  }
}

@riverpod
class ReaderPageLayoutPref extends _$ReaderPageLayoutPref
    with SharedPreferenceEnumClientMixin<ReaderPageLayout> {
  @override
  ReaderPageLayout? build() => initialize(
        ref,
        initial: DBKeys.readerPageLayout.initial,
        key: DBKeys.readerPageLayout.name,
        enumList: ReaderPageLayout.values,
      );
}

@riverpod
class ReaderPageLayoutSkipFirstPagePref
    extends _$ReaderPageLayoutSkipFirstPagePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.readerPageLayoutSkipFirstPage.name,
        initial: DBKeys.readerPageLayoutSkipFirstPage.initial,
      );
}

@riverpod
class ReaderPageLayoutWithMangaId extends _$ReaderPageLayoutWithMangaId {
  Timer? debounce;

  @override
  ReaderPageLayout build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalPageLayout = ref.watch(readerPageLayoutPrefProvider) ??
        DBKeys.readerPageLayout.initial;
    final effectPageLayout = manga?.meta?.readerPageLayout ?? globalPageLayout;

    //print("[UPDATE MangaMeta] manga:$mangaId, effectPageLayout:$effectPageLayout");
    return effectPageLayout;
  }

  void update(ReaderPageLayout layout) {
    state = layout;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kDebounceDuration,
      () {
        AsyncValue.guard(
          () async {
            await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                  mangaId: mangaId,
                  key: MangaMetaKeys.pageLayout.key,
                  value: layout.name,
                );
            await ref
                .read(mangaWithIdProvider(mangaId: mangaId).notifier)
                .refresh();
          },
        );
      },
    );
  }

  void updateLocal(ReaderPageLayout layout) {
    state = layout;
  }
}

@riverpod
class ReaderPageLayoutSkipFirstWithMangaId
    extends _$ReaderPageLayoutSkipFirstWithMangaId {
  Timer? debounce;

  @override
  bool build({required String mangaId}) {
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    final manga = mangaWithId.valueOrNull;

    final globalSkipFirstPage =
        ref.watch(readerPageLayoutSkipFirstPagePrefProvider) ??
            DBKeys.readerPageLayoutSkipFirstPage.initial;
    final effectSkipFirstPage =
        manga?.meta?.readerPageLayoutSkipFirstPage ?? globalSkipFirstPage;

    //print("[UPDATE MangaMeta] manga:$mangaId, effectSkipFirstPage:$effectSkipFirstPage");
    return effectSkipFirstPage;
  }

  void update(bool skip) {
    state = skip;

    if (debounce?.isActive == true) {
      debounce?.cancel();
    }
    debounce = Timer(
      kDebounceDuration,
      () {
        AsyncValue.guard(() async {
          await ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                mangaId: mangaId,
                key: MangaMetaKeys.pageLayoutSkipFirstPage.key,
                value: skip,
              );
          await ref
              .read(mangaWithIdProvider(mangaId: mangaId).notifier)
              .refresh();
        });
      },
    );
  }
}
