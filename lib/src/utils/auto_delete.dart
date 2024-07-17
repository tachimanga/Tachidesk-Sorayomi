import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/manga_book/data/manga_book_repository.dart';
import '../features/manga_book/domain/chapter/chapter_model.dart';
import '../features/manga_book/domain/chapter_batch/chapter_batch_model.dart';
import '../features/manga_book/presentation/downloads/controller/downloads_controller.dart';
import 'log.dart';

part 'auto_delete.g.dart';

@riverpod
class AutoDelete extends _$AutoDelete {
  @override
  int build() {
    log("[Download]AutoDelete init");
    ref.keepAlive();
    return 0;
  }

  void addToDeleteList(Chapter chapter) {
    Future(() {
      try {
        addToDeleteList0(chapter);
      } catch (e) {
        log("[Download]addToDeleteList error $e");
      }
    });
  }

  void addToDeleteList0(Chapter chapter) {
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

  void triggerDelete() {
    Future(() {
      try {
        triggerDelete0();
      } catch (e) {
        log("[Download]triggerDelete error $e");
      }
    });
  }

  void triggerDelete0() {
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
    if (todoList.isEmpty) {
      return;
    }
    final chapterIds = todoList.map((e) => int.parse(e)).toList();
    ref.read(mangaBookRepositoryProvider).modifyBulkChapters(
          batch: ChapterBatch(
            chapterIds: chapterIds,
            change: ChapterChange(delete: true),
          ),
        );
  }
}
