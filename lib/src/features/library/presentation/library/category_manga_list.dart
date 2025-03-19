// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/db_keys.dart';
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/manga_cover/grid/manga_cover_grid_tile.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../../widgets/manga_cover/list/manga_cover_list_tile.dart';
import '../../../../widgets/shell/shell_screen.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../../../manga_book/presentation/updates/controller/update_controller.dart';
import '../../../manga_book/widgets/update_status_fab.dart';
import '../../../settings/presentation/appearance/widgets/grid_cover_min_width.dart';
import '../../../sync/controller/sync_controller.dart';
import 'controller/library_controller.dart';
import 'domain/select_key.dart';
import 'widgets/library_manga_empty_view.dart';

class CategoryMangaList extends HookConsumerWidget {
  const CategoryMangaList({
    super.key,
    required this.categoryId,
    required this.categoryCount,
    required this.selectMangaMap,
  });

  final int categoryId;
  final int categoryCount;
  final ValueNotifier<Map<SelectKey, Manga>?> selectMangaMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider =
        categoryMangaListWithQueryAndFilterProvider(categoryId: categoryId);
    final mangaList = ref.watch(provider);
    final displayMode = ref.watch(libraryDisplayModeProvider);
    final coverWidth =
        ref.watch(gridMinWidthProvider) ?? DBKeys.gridMangaCoverWidth.initial;
    final updateRunning = ref.watch(updateRunningProvider);
    final showUpdateStatus = ref.watch(showUpdateStatusProvider);
    final rawProvider = categoryMangaListWithIdProvider(categoryId: categoryId);
    refresh() => ref.invalidate(rawProvider);
    useEffect(() {
      if (!mangaList.isLoading) refresh();
      return;
    }, []);

    final refreshSignal = ref.watch(updateRefreshSignalProvider);
    useEffect(() {
      if (refreshSignal) {
        refresh();
      }
      return;
    }, [refreshSignal]);

    final scheduleRefreshSignal =
        ref.watch(updateScheduleRefreshSignalProvider);
    useEffect(() {
      if (scheduleRefreshSignal > 0) {
        ref.read(rawProvider.notifier).reloadMangaList();
      }
      return;
    }, [scheduleRefreshSignal]);

    final syncRefreshSignal = ref.watch(syncRefreshSignalProvider);
    useEffect(() {
      if (syncRefreshSignal) {
        refresh();
      }
      return;
    }, [syncRefreshSignal]);

    return mangaList.showUiWhenData(
      context,
      (data) {
        if (data.isBlank) {
          return LibraryMangaEmptyView(
            refresh: refresh,
            categoryId: categoryId,
            categoryCount: categoryCount,
          );
        }
        late final Widget mangaList;
        switch (displayMode) {
          case DisplayMode.grid:
            final grid = GridView.builder(
              controller: mainPrimaryScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: mangaCoverGridDelegate(coverWidth),
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverGridTile(
                manga: data![index],
                selected: _isSelected(data[index]),
                onPressed: () => _onPressItem(context, data[index]),
                onLongPress: () => _onLongPressItem(data[index]),
                showCountBadges: true,
                showDarkOverlay: false,
                decodeWidth: coverWidth.ceil(),
              ),
            );
            mangaList = Padding(
              padding: KEdgeInsets.h8.size,
              child: grid,
            );
            break;
          case DisplayMode.list:
            mangaList = ListView.builder(
              controller: mainPrimaryScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverListTile(
                manga: data![index],
                selected: _isSelected(data[index]),
                onPressed: () => _onPressItem(context, data[index]),
                onLongPress: () => _onLongPressItem(data[index]),
                showCountBadges: true,
              ),
            );
            break;
          case DisplayMode.descriptiveList:
            mangaList = ListView.builder(
              controller: mainPrimaryScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverDescriptiveListTile(
                manga: data![index],
                selected: _isSelected(data[index]),
                onPressed: () => _onPressItem(context, data[index]),
                onLongPress: () => _onLongPressItem(data[index]),
                showBadges: true,
              ),
            );
            break;
          default:
        }
        return RefreshIndicator(
          onRefresh: () async {
            refresh();
            if (!updateRunning && !showUpdateStatus) {
              fireUpdate(ref, ["$categoryId"]);
            }
          },
          child: mangaList,
        );
      },
      refresh: refresh,
    );
  }

  bool _isSelected(Manga manga) {
    final key = SelectKey(categoryId, manga.id ?? 0);
    return selectMangaMap.value?.containsKey(key) == true;
  }

  void _onPressItem(BuildContext context, Manga manga) {
    if (manga.id == null) {
      return;
    }
    final key = SelectKey(categoryId, manga.id!);
    if (selectMangaMap.value != null) {
      selectMangaMap.value =
          selectMangaMap.value.toggleKeyNullable(key, manga);
    } else {
      context.push(Routes.getManga(
        manga.id!,
        categoryId: categoryId,
      ));
    }
  }

  void _onLongPressItem(Manga manga) {
    if (manga.id == null) {
      return;
    }
    final key = SelectKey(categoryId, manga.id!);
    selectMangaMap.value =
        selectMangaMap.value.toggleKeyNullable(key, manga);
  }
}
