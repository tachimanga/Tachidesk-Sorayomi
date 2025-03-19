// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../domain/category/category_model.dart';
import '../controller/library_controller.dart';
import '../domain/select_key.dart';

class LibrarySelectIconButton extends HookConsumerWidget {
  const LibrarySelectIconButton({
    super.key,
    required this.mode,
    required this.categories,
    required this.selectMangaMap,
  });

  final SelectMode mode;
  final List<Category> categories;
  final ValueNotifier<Map<SelectKey, Manga>?> selectMangaMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    return IconButton(
      onPressed: () {
        switch (mode) {
          case SelectMode.between:
            _selectBetween(context, ref);
            break;
          case SelectMode.all:
            _selectAll(context, ref);
            break;
          case SelectMode.invert:
            _selectInvert(context, ref);
            break;
        }
        toast.show(mode.toLocale(context), gravity: ToastGravity.TOP);
      },
      icon: Icon(mode.toIcon()),
    );
  }

  void _selectBetween(BuildContext context, WidgetRef ref) {
    final categoryId = _currentCategoryId(context);
    final mangaList = _fetchCurrentMangaList(ref, categoryId);
    final other = _otherCategoryEntries(categoryId);

    int? firstIndex;
    int? lastIndex;
    final list = [...?mangaList];
    for (int i = 0; i < list.length; i++) {
      final manga = list[i];
      if (manga.id != null &&
          selectMangaMap.value?.containsKey(SelectKey(categoryId, manga.id!)) ==
              true) {
        if (firstIndex == null) {
          firstIndex = i;
        } else {
          lastIndex = i;
        }
      }
    }
    if (firstIndex == null) {
      return;
    }
    if (firstIndex == lastIndex || lastIndex == null) {
      lastIndex = list.length - 1;
    }

    final between = {
      for (int i = 0; i < list.length; i++)
        if (i >= firstIndex && i <= lastIndex && list[i].id != null)
          SelectKey(categoryId, list[i].id!): list[i]
    };
    selectMangaMap.value = {...other, ...between};
  }

  void _selectAll(BuildContext context, WidgetRef ref) {
    final categoryId = _currentCategoryId(context);
    final list = _fetchCurrentMangaList(ref, categoryId);
    final other = _otherCategoryEntries(categoryId);
    final all = {
      for (final i in [...?list])
        if (i.id != null) SelectKey(categoryId, i.id!): i
    };
    selectMangaMap.value = {...other, ...all};
  }

  void _selectInvert(BuildContext context, WidgetRef ref) {
    final categoryId = _currentCategoryId(context);
    final list = _fetchCurrentMangaList(ref, categoryId);
    final other = _otherCategoryEntries(categoryId);
    final invert = {
      for (final i in [...?list])
        if (i.id != null &&
            selectMangaMap.value?.containsKey(SelectKey(categoryId, i.id!)) !=
                true)
          SelectKey(categoryId, i.id!): i
    };
    selectMangaMap.value = {...other, ...invert};
  }

  int _currentCategoryId(BuildContext context) {
    final category = categories[DefaultTabController.of(context).index];
    return category.id ?? 0;
  }

  List<Manga>? _fetchCurrentMangaList(WidgetRef ref, int categoryId) {
    final provider =
        categoryMangaListWithQueryAndFilterProvider(categoryId: categoryId);
    final mangaList = ref.read(provider);
    return mangaList.valueOrNull;
  }

  Map<SelectKey, Manga> _otherCategoryEntries(int categoryId) {
    final map = <SelectKey, Manga>{};
    selectMangaMap.value?.forEach((key, value) {
      if (key.categoryId != categoryId) {
        map[key] = value;
      }
    });
    return map;
  }
}
