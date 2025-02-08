// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/sort_list_tile.dart';
import '../../../domain/category/category_model.dart';
import '../controller/library_controller.dart';

class LibraryMangaSortTile extends ConsumerWidget {
  const LibraryMangaSortTile({
    super.key,
    required this.sortType,
    required this.category,
  });

  final MangaSort sortType;
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = category.id ?? 0;

    final sortByProvider = categorySortWithIdProvider(categoryId: categoryId);
    final sortDirectionProvider =
        categorySortDirectionWithIdProvider(categoryId: categoryId);

    final sortedBy = ref.watch(sortByProvider);
    final sortedDirection = ref.watch(sortDirectionProvider);

    return SortListTile(
      selected: sortType == sortedBy,
      title: Text(sortType.toLocale(context)),
      ascending: sortedDirection.ifNull(true),
      onChanged: (bool? value) => ref
          .read(sortDirectionProvider.notifier)
          .update(!(sortedDirection.ifNull())),
      onSelected: () => ref.read(sortByProvider.notifier).update(sortType),
    );
  }
}
