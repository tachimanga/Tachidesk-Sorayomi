import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
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
class ReaderPaddingLandscapeWithMangaId extends _$ReaderPaddingLandscapeWithMangaId {
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