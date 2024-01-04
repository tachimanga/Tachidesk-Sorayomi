// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../browse_center/presentation/source_manga_list/controller/source_manga_controller.dart';
import '../../../domain/manga/manga_model.dart';

class MangaGenreChip extends HookConsumerWidget {
  const MangaGenreChip({
    super.key,
    required this.manga,
    required this.genre,
  });
  final Manga manga;
  final String genre;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () async {
        final filtersProvider =
            sourceMangaFilterListProvider(manga.sourceId ?? "");
        final filterList = await ref.read(filtersProvider.notifier).reset();
        if (filterList != null) {
          for (int i = 0; i < filterList.length; i++) {
            final filter = filterList[i];
            final state = filter.filterState;
            final newState = state?.mapOrNull(select: (f) {
              final index = f.displayValues?.indexOfFirst((e) => e == genre);
              if (index != -1) {
                return f.copyWith(state: index);
              }
              return null;
            }, group: (g) {
              final innerFilterList = g.state;
              if (innerFilterList != null) {
                for (int j = 0; j < innerFilterList.length; j++) {
                  final innerFilter = innerFilterList[j];
                  final newState =
                      innerFilter.filterState?.mapOrNull(triState: (f) {
                    if (f.name == genre) {
                      return f.copyWith(state: 1 /*STATE_INCLUDE*/);
                    }
                    return null;
                  }, checkBox: (f) {
                    if (f.name == genre) {
                      return f.copyWith(state: true);
                    }
                    return null;
                  });
                  if (newState != null) {
                    final newInnerFilter =
                        innerFilter.copyWith(filterState: newState);
                    final newInnerFilterList =
                        ([...innerFilterList]..replaceRange(
                            j,
                            j + 1,
                            [newInnerFilter],
                          ));
                    return g.copyWith(state: newInnerFilterList);
                  }
                }
              }
              return null;
            });
            if (newState != null) {
              final newFilter = filter.copyWith(filterState: newState);
              final newFilterList = ([...filterList]..replaceRange(
                  i,
                  i + 1,
                  [newFilter],
                ));
              ref.read(filtersProvider.notifier).updateFilter(newFilterList);
              if (context.mounted) {
                context.push(
                  Routes.getSourceManga(
                    manga.sourceId ?? "",
                    SourceType.filter,
                  ),
                );
                return;
              }
            }
          }
        }
        if (context.mounted) {
          context.push(Routes.getSourceManga(
            manga.sourceId ?? "",
            SourceType.filter,
            query: genre,
          ));
        }
      },
      child: Chip(label: Text(genre)),
    );
  }
}
