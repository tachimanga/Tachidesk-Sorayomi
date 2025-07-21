// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../routes/router_config.dart';
import '../../../utils/event_util.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/misc/toast/toast.dart';
import '../../../widgets/popup_Item_with_icon_child.dart';
import '../../library/domain/category/category_model.dart';
import '../../library/presentation/library/controller/library_controller.dart';
import '../data/updates/updates_repository.dart';
import '../presentation/updates/widgets/update_status_summary_sheet_v3.dart';
import 'update_status_fab.dart';

class UpdateStatusPopupMenu extends ConsumerWidget {
  const UpdateStatusPopupMenu({
    super.key,
    this.getCategory,
    this.onTapSelectManga,
    this.showSummaryButton = true,
    this.showRandomButton = false,
  });
  final Category? Function()? getCategory;
  final Function()? onTapSelectManga;
  final bool showSummaryButton;
  final bool showRandomButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
      itemBuilder: (context) {
        final category = getCategory != null ? getCategory!() : null;
        return [
          if (category != null && category.id != null && category.id != 0)
            PopupMenuItem(
              child: PopupItemWithIconChild(
                icon: const Icon(Icons.refresh),
                label: Text(context.l10n!.categoryUpdate),
              ),
              onTap: () => ref
                  .read(updatesRepositoryProvider)
                  .fetchUpdates(categoryIds: [category.id ?? 0]),
            ),
          PopupMenuItem(
            onTap: () => fireGlobalUpdate(ref),
            child: PopupItemWithIconChild(
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n!.globalUpdate),
            ),
          ),
          if (showSummaryButton)
            PopupMenuItem(
              onTap: () => Future.microtask(
                () => showUpdateStatusSummaryBottomSheetV3(context),
              ),
              child: PopupItemWithIconChild(
                icon: const Icon(Icons.info_outline),
                label: Text(context.l10n!.updatesSummary),
              ),
            ),
          if (onTapSelectManga != null)
            PopupMenuItem(
              onTap: onTapSelectManga,
              child: PopupItemWithIconChild(
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.l10n!.label_select),
              ),
            ),
          if (showRandomButton)
            PopupMenuItem(
              onTap: () => _openRandomEntry(context, ref, category, toast),
              child: PopupItemWithIconChild(
                icon: const Icon(Icons.shuffle_sharp),
                label: Text(context.l10n!.action_open_random_manga),
              ),
            ),
        ];
      },
    );
  }

  void _openRandomEntry(
    BuildContext context,
    WidgetRef ref,
    Category? category,
    Toast toast,
  ) {
    logEvent3("LIBRARY:OPEN:RANDOM");
    if (category == null) {
      toast.showError(context.l10n!.information_no_entries_found);
      return;
    }
    final provider = categoryMangaListWithQueryAndFilterProvider(
        categoryId: category.id ?? 0);
    final mangaList = ref.read(provider);
    if (mangaList.hasValue && mangaList.value?.isNotEmpty == true) {
      final list = mangaList.value!;
      final manga = list[Random().nextInt(list.length)];
      if (manga.id == null) {
        return;
      }
      context.push(Routes.getManga(
        manga.id!,
        categoryId: category.id,
      ));
    } else {
      toast.showError(context.l10n!.information_no_entries_found);
    }
  }
}
