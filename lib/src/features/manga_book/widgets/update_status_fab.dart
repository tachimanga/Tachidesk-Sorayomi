// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/db_keys.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/custom_circular_progress_indicator.dart';
import '../../library/domain/category/category_model.dart';
import '../../library/presentation/category/controller/edit_category_controller.dart';
import '../data/updates/updates_repository.dart';
import '../presentation/updates/controller/update_controller.dart';
import 'select_category_to_update_dialog.dart';
import 'update_status_summary_sheet_v2.dart';

class UpdateStatusFab extends ConsumerWidget {
  const UpdateStatusFab({super.key, this.forLibrary});

  final bool? forLibrary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateStatus = ref.watch(updatesSocketProvider);
    final showStatus = (updateStatus.valueOrNull?.showUpdateStatus).ifNull();
    final running = updateStatus.valueOrNull?.running == true;
    final categoryListValue = ref.watch(categoryControllerProvider);

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
          showUpdateStatusSummaryBottomSheetV2(context);
          return;
        }
        categoryListValue.whenOrNull(data: (categoryList) {
          fetchUpdates(context, ref, categoryList);
          return;
        });
      },
    );
  }
}

void fetchUpdates(
  BuildContext context,
  WidgetRef ref,
  List<Category>? categoryList,
) {
  ref.read(showUpdateStatusSwitchProvider.notifier).update(true);
  final selectedCategoryIds = ref.read(categoryIdsToUpdatePrefProvider);
  final alwaysAskSelect = ref.read(alwaysAskCategoryToUpdatePrefProvider) ??
      DBKeys.alwaysAskCategoryToUpdate.initial;

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
}

void fireUpdate(WidgetRef ref, List<String> categoryIds) {
  ref.read(showUpdateStatusSwitchProvider.notifier).update(true);
  if (categoryIds.isEmpty) {
    ref.read(updatesRepositoryProvider).fetchUpdates();
  } else {
    final list = categoryIds.map((e) => int.parse(e)).toList();
    ref.read(updatesRepositoryProvider).fetchUpdates(categoryIds: list);
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
