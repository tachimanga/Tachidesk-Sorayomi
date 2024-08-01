// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../widgets/manga_cover/grid/manga_cover_grid_tile.dart';
import '../../../../manga_book/data/manga_book_repository.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../../manga_book/presentation/manga_details/controller/manga_details_controller.dart';
import '../../../../manga_book/presentation/manga_details/widgets/edit_manga_category_dialog.dart';
import '../../../../settings/presentation/appearance/widgets/grid_cover_min_width.dart';
import '../../../domain/source/source_model.dart';
import 'source_page_error_view.dart';

class SourceMangaGridView extends ConsumerWidget {
  const SourceMangaGridView({super.key, required this.controller, this.source});
  final PagingController<int, Manga> controller;
  final Source? source;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverWidth =
        ref.watch(gridMinWidthProvider) ?? DBKeys.gridMangaCoverWidth.initial;
    return PagedGridView(
      pagingController: controller,
      builderDelegate: PagedChildBuilderDelegate<Manga>(
        firstPageErrorIndicatorBuilder: (context) =>
            SourcePageErrorView(controller: controller, source: source),
        noItemsFoundIndicatorBuilder: (context) => SourcePageErrorView(
            controller: controller,
            source: source,
            message: context.l10n!.noMangaFound),
        itemBuilder: (context, item, index) => MangaCoverGridTile(
          manga: item.copyWith(source: source),
          showDarkOverlay: item.inLibrary.ifNull(),
          onPressed: () {
            if (item.id != null) {
              context.push(
                Routes.getManga(item.id!),
                extra: item.copyWith(source: source),
              );
            }
          },
          onLongPress: () async {
            if (item.id != null) {
              if (item.inLibrary == true) {
                await ref
                    .read(mangaBookRepositoryProvider)
                    .removeMangaFromLibrary("${item.id}");
              } else {
                await showAddToCategoryDialogIfNeeded(context, ref, item);
              }
              await refreshMangaAfterEditCategory(ref, controller, item, index);
            }
          },
          decodeWidth: coverWidth.ceil(),
        ),
      ),
      gridDelegate: mangaCoverGridDelegate(coverWidth),
    );
  }
}
