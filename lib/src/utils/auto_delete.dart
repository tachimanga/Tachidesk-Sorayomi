import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/manga_book/data/manga_book_repository.dart';
import '../features/manga_book/domain/chapter/chapter_model.dart';
import '../features/manga_book/domain/chapter_batch/chapter_batch_model.dart';
import '../features/manga_book/presentation/downloads/controller/downloads_controller.dart';
import 'log.dart';

class AutoDelete {
  static AutoDelete instance = AutoDelete();

  void addToDeleteList(WidgetRef ref, Chapter chapter) {
    Future(() {
      try {
        addToDeleteList0(ref, chapter);
      } catch (e) {
        log("[Download]addToDeleteList error $e");
      }
    });
  }

  void addToDeleteList0(WidgetRef ref, Chapter chapter) {
    final enable = ref.read(deleteDownloadAfterReadPrefProvider) == 1;
    if (!enable) {
      log("[Download]auto delete disable");
      return;
    }
    final todoList = ref.read(deleteDownloadAfterReadTodoListProvider);
    final todoSet = {...?todoList};
    todoSet.add("${chapter.id}");
    ref
        .read(deleteDownloadAfterReadTodoListProvider.notifier)
        .update(todoSet.toList());
    log("[Download]addToDeleteList, list=$todoSet");
  }

  void triggerDelete(WidgetRef ref) {
    Future(() {
      try {
        triggerDelete0(ref);
      } catch (e) {
        log("[Download]triggerDelete error $e");
      }
    });
  }

  void triggerDelete0(WidgetRef ref) {
    final enable = ref.read(deleteDownloadAfterReadPrefProvider) == 1;
    if (!enable) {
      log("[Download]auto delete disable");
      return;
    }

    final todoList = ref.read(deleteDownloadAfterReadTodoListProvider) ?? [];
    ref
        .read(deleteDownloadAfterReadTodoListProvider.notifier)
        .update(<String>[]);
    log("[Download]triggerDelete, list=$todoList");

    final chapterIds = todoList.map((e) => int.parse(e)).toList();
    ref.read(mangaBookRepositoryProvider).modifyBulkChapters(
          batch: ChapterBatch(
            chapterIds: chapterIds,
            change: ChapterChange(delete: true),
          ),
        );
  }
}
