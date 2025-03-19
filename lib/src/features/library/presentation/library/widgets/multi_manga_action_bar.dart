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

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/async_buttons/async_text_button.dart';
import '../../../../manga_book/data/manga_book_repository.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../../manga_book/domain/manga_batch/manga_batch_model.dart';
import '../domain/select_key.dart';
import 'batch_edit_manga_category_dialog.dart';

class MultiMangaActionBar extends ConsumerWidget {
  const MultiMangaActionBar({
    super.key,
    required this.selectedMangaMap,
    required this.afterOptionSelected,
  });

  final ValueNotifier<Map<SelectKey, Manga>?> selectedMangaMap;
  final AsyncValueSetter<Map<SelectKey, Manga>?> afterOptionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    refresh([bool triggerAfterOption = true]) async {
      final prev = selectedMangaMap.value;
      selectedMangaMap.value = null;
      if (triggerAfterOption) await afterOptionSelected(prev);
    }
    final mangaIds = selectedMangaMap.value?.keys.map((e) => e.mangaId).toSet().toList() ?? [];
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return BatchEditMangaCategoryDialog(
                    mangaList: selectedMangaMap.value?.values.toList() ?? [],
                    refresh: refresh,
                  );
                },
              );
            },
            icon: Icon(Icons.label_rounded),
          ),
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MarkReadDialog(
                    mangaIds: mangaIds,
                    refresh: refresh,
                  );
                },
              );
            },
            icon: Icon(Icons.done_all_sharp),
          ),
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return MarkUnreadDialog(
                    mangaIds: mangaIds,
                    refresh: refresh,
                  );
                },
              );
            },
            icon: Icon(Icons.remove_done_sharp),
          ),
          IconButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return RemoveFromLibraryDialog(
                    mangaIds: mangaIds,
                    refresh: refresh,
                  );
                },
              );
            },
            icon: Icon(Icons.delete_sharp),
          ),
        ],
      ),
    );
  }
}

class MarkReadDialog extends ConsumerWidget {
  const MarkReadDialog({
    super.key,
    required this.mangaIds,
    required this.refresh,
  });

  final List<int> mangaIds;
  final AsyncValueSetter<bool> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    return AlertDialog(
      title: Text(context.l10n!.mark_all_read),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.l10n!.cancel),
        ),
        AsyncTextButton(
          child: Text(context.l10n!.mark_as_read),
          onPressed: () async {
            final change = MangaChange(chapterRead: true);
            final changes =
                mangaIds.map((id) => change.copyWith(mangaId: id)).toList();
            (await AsyncValue.guard(
              () async {
                await ref
                    .read(mangaBookRepositoryProvider)
                    .mangaBatchUpdate(input: MangaBatchInput(changes: changes));
                refresh(true);
                if (context.mounted) {
                  context.pop();
                }
              },
            ))
                .showToastOnError(toast);
          },
        ),
      ],
    );
  }
}

class MarkUnreadDialog extends ConsumerWidget {
  const MarkUnreadDialog({
    super.key,
    required this.mangaIds,
    required this.refresh,
  });

  final List<int> mangaIds;
  final AsyncValueSetter<bool> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    return AlertDialog(
      title: Text(context.l10n!.mark_all_unread),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.l10n!.cancel),
        ),
        AsyncTextButton(
          child: Text(context.l10n!.mark_as_unread),
          onPressed: () async {
            final change = MangaChange(chapterRead: false);
            final changes =
                mangaIds.map((id) => change.copyWith(mangaId: id)).toList();
            (await AsyncValue.guard(
              () async {
                await ref
                    .read(mangaBookRepositoryProvider)
                    .mangaBatchUpdate(input: MangaBatchInput(changes: changes));
                refresh(true);
                if (context.mounted) {
                  context.pop();
                }
              },
            ))
                .showToastOnError(toast);
          },
        ),
      ],
    );
  }
}

class RemoveFromLibraryDialog extends HookConsumerWidget {
  const RemoveFromLibraryDialog({
    super.key,
    required this.mangaIds,
    required this.refresh,
  });

  final List<int> mangaIds;
  final AsyncValueSetter<bool> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final removeFromLibrary = useState(false);

    return AlertDialog(
      title: Text(context.l10n!.remove),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: true,
            title: Text(context.l10n!.remove_downloads),
            onChanged: null,
          ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            value: removeFromLibrary.value,
            title: Text(context.l10n!.remove_from_library),
            onChanged: (value) => removeFromLibrary.value = value == true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.l10n!.cancel),
        ),
        AsyncTextButton(
          showLoading: true,
          child: Text(context.l10n!.remove),
          onPressed: () async {
            final change = MangaChange(
              removeFromLibrary: removeFromLibrary.value,
              removeDownloads: true,
            );
            final changes =
                mangaIds.map((id) => change.copyWith(mangaId: id)).toList();
            (await AsyncValue.guard(
              () async {
                await ref.read(mangaBookRepositoryProvider).mangaBatchUpdate(
                      input: MangaBatchInput(changes: changes),
                    );
                refresh(true);
                if (context.mounted) {
                  context.pop();
                }
              },
            ))
                .showToastOnError(toast);
          },
        ),
      ],
    );
  }
}
