// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../global_providers/global_providers.dart';
import '../../../routes/router_config.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/misc/toast/toast.dart';
import '../../../widgets/custom_circular_progress_indicator.dart';
import '../data/downloads/downloads_repository.dart';
import '../data/manga_book_repository.dart';
import '../domain/chapter/chapter_model.dart';
import '../domain/chapter_batch/chapter_batch_model.dart';
import '../presentation/downloads/service/download_ticket_service.dart';
import '../presentation/downloads/widgets/download_reward_ad_dialog.dart';

class DownloadStatusIcon extends HookConsumerWidget {
  const DownloadStatusIcon({
    super.key,
    required this.updateData,
    required this.chapter,
    required this.mangaId,
    required this.isDownloaded,
  });
  final AsyncCallback updateData;
  final Chapter chapter;
  final int mangaId;
  final bool isDownloaded;

  Future<void> newUpdatePair(
      WidgetRef ref, ValueNotifier<bool> isLoading) async {
    try {
      isLoading.value = true;
      await updateData();
      isLoading.value = false;
    } catch (e) {
      //
    }
  }

  Future toggleChapterToQueue(
    Toast toast,
    BuildContext context,
    WidgetRef ref, {
    bool isAdd = false,
    bool isRemove = false,
    bool isError = false,
  }) async {
    try {
      if (chapter.index == null) return;
      (await AsyncValue.guard(() async {
        final repo = ref.read(downloadsRepositoryProvider);
        if (isRemove || isError) {
          await repo.removeChapterFromDownloadQueue(mangaId, chapter.index!);
        }
        if (isAdd || isError) {
          if (!context.mounted) {
            return;
          }
          await showAdDialogIfNeeded(
            context: context,
            ref: ref,
            chaptersCount: 1,
            onPass: () async {
              await repo.addChapterToDownloadQueue(mangaId, chapter.index!);
            },
          );
        }
      }))
          .showToastOnError(toast);
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    final pipe = ref.watch(getMagicPipeProvider);
    final toast = ref.watch(toastProvider(context));
    final download = chapter.id.isNull
        ? null
        : ref.watch(downloadsFromIdProvider(chapter.id!));
    useEffect(() {
      if (download?.state == "Finished") {
        Future.microtask(() => newUpdatePair(ref, isLoading));
      }
      return;
    }, [download?.state]);

    if (isLoading.value) {
      return Padding(
        padding: KEdgeInsets.h8.size,
        child: MiniCircularProgressIndicator(color: context.iconColor),
      );
    } else {
      if (download != null) {
        return download.state == "Error"
            ? IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(context.l10n!.downloadFailed),
                        content: Text(
                            '${download.error != null ? "${context.l10n!.errorMessageFrom(download.error ?? "")}\n" : ""}${context.l10n!.downloadTip}'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(context.l10n!.close),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pop();
                              context.push(Routes.getReader(
                                "$mangaId",
                                "${chapter.index}",
                              ));
                            },
                            child: Text(context.l10n!.open),
                          ),
                          TextButton(
                            onPressed: () {
                              context.pop();
                              toggleChapterToQueue(toast, context, ref,
                                  isError: true);
                            },
                            child: Text(context.l10n!.retry),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.replay_rounded),
              )
            : IconButton(
                onPressed: () =>
                    toggleChapterToQueue(toast, context, ref, isRemove: true),
                icon: MiniCircularProgressIndicator(
                  value: download.progress == 0 ? null : download.progress,
                  color: context.iconColor,
                ),
              );
      } else {
        if (isDownloaded) {
          return IconButton(
            icon: const Icon(Icons.check_circle_rounded),
            onPressed: () async {
              (await AsyncValue.guard(
                () => ref.read(mangaBookRepositoryProvider).modifyBulkChapters(
                      batch: ChapterBatch(
                        chapterIds: [chapter.id!],
                        change: ChapterChange(delete: true),
                      ),
                    ),
              ))
                  .showToastOnError(toast);
              await newUpdatePair(ref, isLoading);
            },
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () {
              pipe.invokeMethod("LogEvent", "DOWN_ADD_CHAPTER");
              toggleChapterToQueue(toast, context, ref, isAdd: true);
            },
          );
        }
      }
    }
  }
}
