// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/multi_select_popup.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../library/data/category/category_repository.dart';
import '../../../../library/domain/category/category_model.dart';
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../controller/category_settings_controller.dart';

class DefaultCategoriesSelectTile extends ConsumerWidget {
  const DefaultCategoriesSelectTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final customCategoryList = categoryList.valueOrNull
            ?.where((e) => e.id != null && e.id != 0)
            .map((e) => CategoryItem(e.id!, e.name ?? "", e))
            .toList() ??
        [];
    final alwaysAsk =
        ref.watch(defaultCategoryPrefProvider) == kCategoryAlwaysAskValue;

    // always ask, default, custom categories.
    final alwaysAskItem =
        CategoryItem(-1, context.l10n!.default_category_summary, null);
    final defaultItem = CategoryItem(0, context.l10n!.label_default, null);
    final list = [alwaysAskItem, defaultItem, ...customCategoryList];

    final selectedItem = alwaysAsk
        ? alwaysAskItem
        : customCategoryList
                .where((e) => e.category?.defaultCategory == true)
                .firstOrNull ??
            defaultItem;

    return ListTile(
      title: Text(context.l10n!.default_category),
      subtitle: Text(selectedItem.name),
      leading: const Icon(Icons.radio_button_checked_rounded),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<CategoryItem>(
          title: context.l10n!.default_category,
          optionList: list,
          value: selectedItem,
          optionDisplayName: (value) => value.name,
          onChange: (value) async {
            ref
                .read(defaultCategoryPrefProvider.notifier)
                .update(value == alwaysAskItem ? kCategoryAlwaysAskValue : 0);
            for (final item in customCategoryList) {
              final target = item == value ? true : false;
              if (item.category!.defaultCategory == target) {
                continue;
              }
              final category = item.category!.copyWith(
                defaultCategory: target,
              );
              await ref
                  .read(categoryControllerProvider.notifier)
                  .editCategory(category);
            }
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}

class CategoryItem {
  final int id;
  final String name;
  final Category? category;
  CategoryItem(this.id, this.name, this.category);
}
