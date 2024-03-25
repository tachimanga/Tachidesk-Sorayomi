// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/db_keys.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../library/domain/category/category_model.dart';
import '../../library/presentation/category/controller/edit_category_controller.dart';
import '../data/updates/updates_repository.dart';
import '../presentation/updates/controller/update_controller.dart';
import 'select_category_to_update_dialog.dart';
import 'update_status_summary_sheet.dart';

class UpdateStatusPopupMenu extends ConsumerWidget {
  const UpdateStatusPopupMenu({
    super.key,
    this.getCategory,
    this.showSummaryButton = true,
  });
  final Category? Function()? getCategory;
  final bool showSummaryButton;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryListValue = ref.watch(categoryControllerProvider);
    final selectedCategoryIds = ref.watch(categoryIdsToUpdatePrefProvider);
    final alwaysAskSelect = ref.watch(alwaysAskCategoryToUpdatePrefProvider) ??
        DBKeys.alwaysAskCategoryToUpdate.initial;

    return PopupMenuButton(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
      itemBuilder: (context) {
        final category = getCategory != null ? getCategory!() : null;
        return [
          if (category != null && category.id != null && category.id != 0)
            PopupMenuItem(
              child: Text(context.l10n!.categoryUpdate),
              onTap: () => ref
                  .read(updatesRepositoryProvider)
                  .fetchUpdates(categoryIds: [category.id ?? 0]),
            ),
          PopupMenuItem(
            onTap: () async {
              categoryListValue.whenOrNull(data: (categoryList) {
                if (categoryList == null ||
                    categoryList.isEmpty ||
                    categoryList.length == 1) {
                  ref.read(updatesRepositoryProvider).fetchUpdates();
                  return;
                }
                if (alwaysAskSelect) {
                  showDialog(
                    context: context,
                    builder: (context) => SelectCategoryToUpdateDialog(
                      onSelectCategory: (List<String> categoryIds) {
                        fireUpdate(ref, categoryIds);
                      },
                    ),
                  );
                } else {
                  fireUpdate(ref, selectedCategoryIds ?? []);
                }
                return;
              });
            },
            child: Text(context.l10n!.globalUpdate),
          ),
          if (showSummaryButton)
            PopupMenuItem(
              onTap: () => Future.microtask(
                () => showUpdateStatusSummaryBottomSheet(context),
              ),
              child: Text(
                context.l10n!.updatesSummary,
              ),
            ),
        ];
      },
    );
  }

  void fireUpdate(WidgetRef ref, List<String> categoryIds) {
    if (categoryIds.isEmpty) {
      ref.read(updatesRepositoryProvider).fetchUpdates();
    } else {
      final list = categoryIds.map((e) => int.parse(e)).toList();
      ref.read(updatesRepositoryProvider).fetchUpdates(categoryIds: list);
    }
  }
}
