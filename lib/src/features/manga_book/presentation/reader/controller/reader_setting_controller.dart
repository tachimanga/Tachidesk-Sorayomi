import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../settings/presentation/reader/widgets/reader_padding_slider/reader_padding_slider.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';

part 'reader_setting_controller.g.dart';

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
