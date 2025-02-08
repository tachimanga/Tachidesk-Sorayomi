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

class LibraryMangaSortGlobalTile extends ConsumerWidget {
  const LibraryMangaSortGlobalTile({
    super.key,
    required this.category,
  });

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = category.id ?? 0;

    final categorySortByProvider =
        categorySortWithIdProvider(categoryId: categoryId);
    final categorySortDirectionProvider =
        categorySortDirectionWithIdProvider(categoryId: categoryId);

    final categorySortedDirection = ref.watch(categorySortDirectionProvider);
    final categorySortedBy = ref.watch(categorySortByProvider);

    final globalSortDirection = ref.watch(libraryMangaSortDirectionProvider);
    final globalSortBy = ref.watch(libraryMangaSortProvider);

    final enable = categorySortedDirection != globalSortDirection ||
        categorySortedBy != globalSortBy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(
          child: TextButton(
            onPressed: enable
                ? () {
                    ref
                        .read(libraryMangaSortDirectionProvider.notifier)
                        .update(categorySortedDirection);
                    ref
                        .read(libraryMangaSortProvider.notifier)
                        .update(categorySortedBy);

                    ref
                        .read(categorySortDirectionProvider.notifier)
                        .update(null);
                    ref.read(categorySortByProvider.notifier).update(null);
                  }
                : null,
            child: Text(context.l10n!.set_as_default),
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: enable
                ? () {
                    ref
                        .read(categorySortDirectionProvider.notifier)
                        .update(null);
                    ref.read(categorySortByProvider.notifier).update(null);
                  }
                : null,
            child: Text(context.l10n!.reset_to_default),
          ),
        ),
      ],
    );
  }
}
