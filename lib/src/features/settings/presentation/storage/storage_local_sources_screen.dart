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

import '../../../../constants/app_sizes.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/manga_cover_util.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../../../widgets/server_image.dart';
import '../../../manga_book/data/manga_book_repository.dart';
import '../../../manga_book/domain/manga_batch/manga_batch_model.dart';
import 'controller/stroage_controller.dart';
import 'domain/storage_model.dart';
import 'domain/storage_select_key.dart';
import 'utils/storage_util.dart';
import 'widgets/storage_action_bar.dart';

class StorageLocalSourcesScreen extends HookConsumerWidget {
  const StorageLocalSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final showSearch = useState(false);

    final localMangaList = ref.watch(localSourceMangaListProvider);
    final viewModelList = ref.watch(localMangaViewModelListFilterProvider);
    refresh() => ref.refresh(localSourceMangaListProvider.future);

    final selectedMap =
        useState<Map<SelectKey, StorageLocalMangaViewModel>?>(null);

    final cacheSize = selectedMap.value?.values
            .fold(0, (p, e) => p + (e.rawInfo?.size ?? 0)) ??
        0;

    final working = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.local_source),
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSizeV2(
            showTextField: showSearch.value,
          ),
          child: Column(
            children: [
              if (showSearch.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: SearchField(
                    initialText: ref.read(storageLocalMangaQueryProvider),
                    onChanged: (val) => ref
                        .read(storageLocalMangaQueryProvider.notifier)
                        .update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showSearch.value = true,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: localMangaList.showUiWhenData(
        context,
        (list) {
          final data = viewModelList.valueOrNull;
          if (data.isNullOrEmpty) {
            return Emoticons(
              text: context.l10n!.noMangaFound,
              button: TextButton(
                onPressed: refresh,
                child: Text(context.l10n!.refresh),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final e = data![index];
                      final selectKey = SelectKey(null, e.rawInfo?.name, null);
                      final selected =
                          selectedMap.value?.containsKey(selectKey) == true;
                      return MangaCoverListTile(
                        e: e,
                        onPressed: () {
                          selectedMap.value =
                              selectedMap.value.toggleKeyNullable(selectKey, e);
                        },
                        selected: selected,
                      );
                    },
                  ),
                ),
                StorageActionBar(
                  onTapSelectAll: selectedMap.value?.length == data?.length
                      ? null
                      : () {
                          selectedMap.value = {
                            for (final i in data!)
                              SelectKey(null, i.rawInfo?.name, null): i
                          };
                        },
                  onTapDeselect: selectedMap.value?.isEmpty == true
                      ? null
                      : () {
                          selectedMap.value = {};
                        },
                  onTapRemove: selectedMap.value?.isEmpty == true ||
                          working.value ||
                          cacheSize <= 0
                      ? null
                      : () {
                          _showConfirm(
                            context,
                            ref,
                            toast,
                            working,
                            selectedMap,
                            cacheSize,
                          );
                        },
                  size: cacheSize > 0 ? cacheSize : null,
                ),
              ],
            ),
          );
        },
        refresh: refresh,
      ),
    );
  }

  void _showConfirm(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    ValueNotifier<bool> working,
    ValueNotifier<Map<SelectKey, StorageLocalMangaViewModel>?> selectedMap,
    int cacheSize,
  ) {
    showDialog(
      context: context,
      builder: (innerCtx) {
        return AlertDialog(
          icon: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
          content: Text(
            context.l10n!.storage_remove_confirm,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => innerCtx.pop(),
                  child: Text(context.l10n!.cancel),
                ),
                const SizedBox(
                  width: 15,
                ),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    _doRemoveMangas(
                      context,
                      ref,
                      toast,
                      working,
                      selectedMap,
                      cacheSize,
                    );
                  },
                  child: Text(context.l10n!.storage_remove_label),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _doRemoveMangas(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    ValueNotifier<bool> working,
    ValueNotifier<Map<SelectKey, StorageLocalMangaViewModel>?> selectedMap,
    int cacheSize,
  ) async {
    final selectedList = selectedMap.value!.values.toList();
    String? error;
    try {
      logEvent3("STORAGE:LOCALS:REMOVE", {"x": "${selectedList.length}"});
      working.value = true;
      showDialog(
        context: context,
        barrierDismissible: kDebugMode ? true : false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const CenterCircularProgressIndicator(),
            content: Text(
              context.l10n!.storage_removing_label,
              textAlign: TextAlign.center,
            ),
          );
        },
      );

      // 1. Remove from Library
      final changes = selectedList
          .where((e) => e.manga?.id != null)
          .map((e) => MangaChange(
                mangaId: e.manga?.id,
                removeFromLibrary: true,
              ))
          .toList();
      if (changes.isNotEmpty) {
        try {
          await ref
              .read(mangaBookRepositoryProvider)
              .mangaBatchUpdate(input: MangaBatchInput(changes: changes));
        } catch (e) {
          error = e.toString();
        }
      }

      // 2. Remove from storage
      final paths = selectedList
          .where((e) => e.rawInfo?.name?.isNotEmpty == true)
          .map((e) => "/Documents/local/${e.rawInfo?.name}")
          .toList();
      if (paths.isNotEmpty) {
        try {
          await ref.read(storageActionProvider).deleteFilesAtPaths(paths);
        } catch (e) {
          error = e.toString();
        }
      }
    } finally {
      if (context.mounted) {
        working.value = false;
        invalidStorageProviders(ref);
        context.pop();
        if (error != null) {
          toast.showError(error);
        } else {
          selectedMap.value = {};
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
                title: Text(context.l10n!.storage_removed_label),
                content: Text(
                  context.l10n!.storage_space_freed_up(
                      cacheSize.toFormattedSize() ?? ""),
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(context.l10n!.got_it),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}

class MangaCoverListTile extends ConsumerWidget {
  const MangaCoverListTile({
    super.key,
    required this.e,
    this.onPressed,
    this.selected = false,
  });

  final StorageLocalMangaViewModel e;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          SizedBox(width: 15),
          selected
              ? Icon(Icons.check_circle, color: selectedColor)
              : const Icon(Icons.radio_button_unchecked),
          SizedBox(width: 4),
          Padding(
            padding: KEdgeInsets.a8.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ServerImage(
                imageUrl: e.manga?.thumbnailUrl ?? "",
                extInfo: CoverExtInfo.build(e.manga),
                size: const Size.square(48),
                decodeWidth: 48,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (e.rawInfo?.name ?? context.l10n!.unknownManga),
                  style: context.textTheme.titleSmall?.copyWith(height: 1),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  "${e.rawInfo?.size.toFormattedSize()}",
                  style: context.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: e.manga?.id != null
                ? () => context.push(Routes.getManga(e.manga!.id!))
                : null,
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}
