// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../domain/category/category_model.dart';
import '../controller/library_controller.dart';

class LibraryCategoryTab extends HookConsumerWidget {
  const LibraryCategoryTab(
      {super.key, required this.category, required this.showMangaCount});

  final Category category;
  final bool showMangaCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text =
        category.id == 0 ? context.l10n!.label_default : category.name ?? "";
    if (!showMangaCount) {
      return Tab(text: text);
    }

    final provider = categoryMangaListWithQueryAndFilterProvider(
        categoryId: category.id ?? 0);
    final mangaList = ref.watch(provider);
    final list = mangaList.valueOrNull;

    if (list == null) {
      return Tab(text: text);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tab(child: Text(text, softWrap: false, overflow: TextOverflow.fade)),
        Badge(
          label: Text("${list.length}"),
          textColor: context.textTheme.labelSmall?.color,
          backgroundColor: Colors.grey.withOpacity(.2),
        )
      ],
    );
  }
}
