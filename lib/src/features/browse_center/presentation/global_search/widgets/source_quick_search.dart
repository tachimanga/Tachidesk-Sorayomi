// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/manga_cover/grid/manga_cover_grid_tile.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../domain/source/source_model.dart';
import '../../migrate/widgets/migrate_manga_dialog.dart';

class SourceShortSearch extends StatelessWidget {
  const SourceShortSearch({
    super.key,
    required this.source,
    required this.mangaList,
    this.query,
    this.migrateSrcManga,
  });
  final Source source;
  final AsyncValue<List<Manga>> mangaList;
  final String? query;
  final Manga? migrateSrcManga;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(source.displayName ?? source.name ?? ""),
          trailing: const Icon(Icons.arrow_forward_rounded),
          onTap: () => context.push(
            Routes.getSourceManga(
              source.id!,
              SourceType.filter,
              query: query,
            ),
          ),
        ),
        mangaList.showUiWhenData(
          context,
          (data) => data.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      context.l10n!.noResultFound,
                      style: context.textTheme.bodyLarge
                          ?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SizedBox(
                  height: 192,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildItem(context, data[index]);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, Manga i) {
    return SizedBox(
      width: 144,
      height: 192,
      child: MangaCoverGridTile(
        manga: i,
        showDarkOverlay: i.inLibrary.ifNull(),
        decodeWidth: 144,
        onPressed: () {
          if (migrateSrcManga != null && migrateSrcManga!.id != i.id) {
            showDialog(
              context: context,
              builder: (context) => MigrateMangaDialog(
                srcManga: migrateSrcManga!,
                destManga: i,
              ),
            );
            return;
          }
          if (i.id != null) {
            context.push(Routes.getManga(i.id!));
          }
        },
      ),
    );
  }
}
