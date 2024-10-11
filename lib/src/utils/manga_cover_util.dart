import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/enum.dart';
import '../features/manga_book/domain/manga/manga_model.dart';
import 'extensions/custom_extensions.dart';

class CoverExtInfo {

  static Map<String, String> build(Manga? manga) {
    final extInfo = <String, String>{};
    if (manga == null) {
      return extInfo;
    }
    if (manga.id != null) {
      extInfo["mangaId"] = "${manga.id}";
    }
    if (manga.inLibrary == true) {
      extInfo["inLibrary"] = "1";
    }
    return extInfo;
  }

  static String? fetchMangaId(Map<String, String>? extInfo) {
    final mangaId = extInfo?["mangaId"];
    if (mangaId == null || mangaId.isEmpty) {
      return null;
    }
    return mangaId;
  }

  static bool fetchInLibrary(Map<String, String>? extInfo) {
    return extInfo?["inLibrary"] == "1";
  }
}

