// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/db_keys.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/pop_button.dart';
import '../../library/presentation/category/controller/edit_category_controller.dart';
import '../presentation/updates/controller/update_controller.dart';

class SelectCategoryToUpdateDialog extends HookConsumerWidget {
  const SelectCategoryToUpdateDialog({
    super.key,
    this.onSelectCategory,
  });

  final ValueSetter<List<String>>? onSelectCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final allCategoryIds =
        categoryList.valueOrNull?.map((e) => "${e.id}").toList();
    final selectedCategoryIds = ref.watch(categoryIdsToUpdatePrefProvider);
    final selectedCategoryIdSet = selectedCategoryIds.isBlank
        ? {...?allCategoryIds}
        : {...?selectedCategoryIds};
    final alwaysAskSelect = ref.watch(alwaysAskCategoryToUpdatePrefProvider) ??
        DBKeys.alwaysAskCategoryToUpdate.initial;

    return AlertDialog(
      title: Text(context.l10n!.select_category_to_update),
      contentPadding: KEdgeInsets.h8v16.size,
      actions: [
        const PopButton(),
        ElevatedButton(
          onPressed: () async {
            if (onSelectCategory != null) {
              onSelectCategory!(selectedCategoryIds ?? []);
            }
            if (context.mounted) {
              context.pop();
            }
          },
          child: onSelectCategory == null
              ? Text(context.l10n!.ok)
              : selectedCategoryIds.isBlank
                  ? Text(context.l10n!.update_all)
                  : Text(context.l10n!.update),
        ),
      ],
      content: categoryList.showUiWhenData(
        context,
        (data) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.height * .7),
            child: data.isBlank
                ? Padding(
                    padding: KEdgeInsets.h16.size,
                    child: Text(context.l10n!.noCategoriesFoundAlt),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final category in data!)
                          CheckboxListTile(
                            onChanged: (value) {
                              if (value == true) {
                                selectedCategoryIdSet.add("${category.id}");
                              } else {
                                selectedCategoryIdSet.remove("${category.id}");
                              }
                              if (selectedCategoryIdSet
                                  .containsAll(allCategoryIds ?? [])) {
                                selectedCategoryIdSet.clear();
                              }
                              ref
                                  .read(
                                      categoryIdsToUpdatePrefProvider.notifier)
                                  .update([...selectedCategoryIdSet]);
                            },
                            value: selectedCategoryIdSet
                                .contains("${category.id}"),
                            title: Text(category.name ?? ""),
                          ),
                        const SizedBox(
                          height: 10,
                        ),
                        CheckboxListTile(
                          controlAffinity: ListTileControlAffinity.leading,
                          value: alwaysAskSelect,
                          title: Text(context.l10n!.always_ask),
                          onChanged: ref
                              .read(alwaysAskCategoryToUpdatePrefProvider
                                  .notifier)
                              .update,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
