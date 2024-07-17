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
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/manga_cover/grid/manga_cover_grid_tile.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../../widgets/manga_cover/list/manga_cover_list_tile.dart';
import '../../../manga_book/presentation/manga_details/widgets/edit_manga_category_dialog.dart';
import '../../../manga_book/presentation/updates/controller/update_controller.dart';
import '../../../manga_book/widgets/update_status_fab.dart';
import '../../../settings/presentation/appearance/widgets/grid_cover_min_width.dart';
import 'controller/library_controller.dart';

class CategoryMangaList extends HookConsumerWidget {
  const CategoryMangaList({super.key, required this.categoryId});
  final int categoryId;
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
    refresh() => ref.invalidate(categoryMangaListProvider(categoryId));
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

    return mangaList.showUiWhenData(
      context,
      (data) {
        if (data.isBlank) {
          return Emoticons(
            text: context.l10n!.noCategoryMangaFound,
            button: TextButton(
              onPressed: refresh,
              child: Text(context.l10n!.refresh),
            ),
          );
        }
        late final Widget mangaList;
        switch (displayMode) {
          case DisplayMode.grid:
            mangaList = GridView.builder(
              gridDelegate: mangaCoverGridDelegate(coverWidth),
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverGridTile(
                onLongPress: () async {
                  if (data[index].id != null) {
                    await showDialog(
                      context: context,
                      builder: (context) => EditMangaCategoryDialog(
                        mangaId: "${data[index].id}",
                        manga: data[index],
                      ),
                    );
                    refresh();
                  }
                },
                manga: data![index],
                onPressed: () {
                  if (data[index].id != null) {
                    context.push(Routes.getManga(
                      data[index].id!,
                      categoryId: categoryId,
                    ));
                  }
                },
                showCountBadges: true,
                showDarkOverlay: false,
                decodeWidth: coverWidth.ceil(),
              ),
            );
            break;
          case DisplayMode.list:
            mangaList = ListView.builder(
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverListTile(
                manga: data![index],
                onPressed: () {
                  if (data[index].id != null) {
                    context.push(Routes.getManga(
                      data[index].id!,
                      categoryId: categoryId,
                    ));
                  }
                },
                onLongPress: () async {
                  if (data[index].id != null) {
                    await showDialog(
                      context: context,
                      builder: (context) => EditMangaCategoryDialog(
                        mangaId: "${data[index].id}",
                        manga: data[index],
                      ),
                    );
                    refresh();
                  }
                },
                showCountBadges: true,
              ),
            );
            break;
          case DisplayMode.descriptiveList:
            mangaList = ListView.builder(
              itemCount: data?.length ?? 0,
              itemBuilder: (context, index) => MangaCoverDescriptiveListTile(
                manga: data![index],
                onPressed: () {
                  if (data[index].id != null) {
                    context.push(Routes.getManga(
                      data[index].id!,
                      categoryId: categoryId,
                    ));
                  }
                },
                onLongPress: () async {
                  if (data[index].id != null) {
                    await showDialog(
                      context: context,
                      builder: (context) => EditMangaCategoryDialog(
                        mangaId: "${data[index].id}",
                        manga: data[index],
                      ),
                    );
                    refresh();
                  }
                },
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
}
