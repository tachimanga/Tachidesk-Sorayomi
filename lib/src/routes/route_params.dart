import '../features/manga_book/domain/manga/manga_model.dart';

class GlobalSearchInput {
  String? query;
  Manga? manga;

  GlobalSearchInput(this.query, {this.manga});
}
