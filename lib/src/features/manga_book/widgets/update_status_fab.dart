// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tachidesk_sorayomi/src/features/manga_book/widgets/select_category_to_update_dialog.dart';

import '../../../constants/db_keys.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/custom_circular_progress_indicator.dart';
import '../../library/presentation/category/controller/edit_category_controller.dart';
import '../data/updates/updates_repository.dart';
import '../presentation/updates/controller/update_controller.dart';
import 'update_status_summary_sheet.dart';

class UpdateStatusFab extends ConsumerWidget {
  const UpdateStatusFab({super.key, this.forLibrary});

  final bool? forLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(updatesSocketProvider);
    final showStatus = (updateStatus.valueOrNull?.showUpdateStatus).ifNull();
    final running = updateStatus.valueOrNull?.running == true;

    final categoryListValue = ref.watch(categoryControllerProvider);
    final selectedCategoryIds = ref.watch(categoryIdsToUpdatePrefProvider);
    final alwaysAskSelect = ref.watch(alwaysAskCategoryToUpdatePrefProvider) ??
        DBKeys.alwaysAskCategoryToUpdate.initial;

    if (forLibrary == true && !running) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      icon: showStatus || running
          ? MiniCircularProgressIndicator(color: context.iconColor)
          : const Icon(Icons.refresh),
      label: showStatus
          ? Text("${updateStatus.valueOrNull?.updateChecked.padLeft()}"
              "/${updateStatus.valueOrNull?.total.padLeft()}")
          : Text(context.l10n!.update),
      onPressed: () async {
        if (showStatus) {
          showUpdateStatusSummaryBottomSheet(context);
          return;
        }
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

class UpdateSettingIcon extends ConsumerWidget {
  const UpdateSettingIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const SelectCategoryToUpdateDialog(),
        );
      },
    );
  }
}
