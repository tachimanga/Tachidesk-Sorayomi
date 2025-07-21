
import 'package:collection/collection.dart';

import '../constants/enum.dart';
import '../features/manga_book/domain/chapter/chapter_model.dart';


int Function(Chapter m1, Chapter m2) chapterSortComparator(
    ChapterSort? sortedBy) {
  int applyChapterSort(Chapter m1, Chapter m2) {
    switch (sortedBy) {
      case ChapterSort.fetchedDate:
        final i = (m1.uploadDate ?? 0).compareTo(m2.uploadDate ?? 0);
        return i != 0 ? i : (m1.index ?? 0).compareTo(m2.index ?? 0);
      case ChapterSort.chapterName:
        final i = compareNatural(m1.name ?? "", m2.name ?? "");
        return i != 0 ? i : (m1.index ?? 0).compareTo(m2.index ?? 0);
      case ChapterSort.source:
      default:
        return (m1.index ?? 0).compareTo(m2.index ?? 0);
    }
  }

  return applyChapterSort;
}
