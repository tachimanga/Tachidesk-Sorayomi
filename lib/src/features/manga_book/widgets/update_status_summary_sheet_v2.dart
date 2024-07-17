// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../routes/router_config.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/manga_cover/list/manga_cover_list_tile.dart';
import '../data/updates/updates_repository.dart';
import '../domain/manga/manga_model.dart';
import '../domain/update_status/update_status_model.dart';
import 'update_status_popup_menu.dart';

class UpdateStatusSummaryDialogV2 extends HookConsumerWidget {
  const UpdateStatusSummaryDialogV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUpdate = ref.watch(updateSummaryProvider);
    final statusUpdateStream = ref.watch(updatesSocketProvider);
    final AsyncValue<UpdateStatus?> finalStatus =
        (statusUpdateStream.valueOrNull?.total.isGreaterThan(0)).ifNull()
            ? statusUpdateStream
            : statusUpdate;

    final runningExpanded = useState(true);
    final pendingExpanded = useState(false);
    final completedExpanded = useState(false);
    final failedExpanded = useState(true);

    final runningCount = _buildSectionItemCount(
      list: finalStatus.valueOrNull?.statusMap?.running,
      expanded: runningExpanded.value,
    );
    final pendingCount = _buildSectionItemCount(
      list: finalStatus.valueOrNull?.statusMap?.pending,
      expanded: pendingExpanded.value,
    );
    final completedCount = _buildSectionItemCount(
      list: finalStatus.valueOrNull?.statusMap?.completed,
      expanded: completedExpanded.value,
    );
    final failedCount = _buildSectionItemCount(
      list: finalStatus.valueOrNull?.statusMap?.failed,
      expanded: failedExpanded.value,
    );
    final itemCount =
        runningCount + pendingCount + completedCount + failedCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.updatesSummary),
        actions: const [UpdateStatusPopupMenu(showSummaryButton: false)],
      ),
      body: finalStatus.showUiWhenData(
        context,
        (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(updateSummaryProvider.future),
          child: ListView.builder(
            itemBuilder: (context, index) {
              var offset = 0;

              if (index >= offset && index < offset + runningCount) {
                return _sectionItemBuilder(
                  context,
                  const ValueKey('running'),
                  data!.statusMap!.running!,
                  index - offset,
                  context.l10n!.running,
                  runningExpanded,
                );
              }
              offset += runningCount;

              if (index >= offset && index < offset + pendingCount) {
                return _sectionItemBuilder(
                  context,
                  const ValueKey('pending'),
                  data!.statusMap!.pending!,
                  index - offset,
                  context.l10n!.pending,
                  pendingExpanded,
                );
              }
              offset += pendingCount;

              if (index >= offset && index < offset + completedCount) {
                return _sectionItemBuilder(
                  context,
                  const ValueKey('completed'),
                  data!.statusMap!.completed!,
                  index - offset,
                  context.l10n!.completed,
                  completedExpanded,
                );
              }
              offset += completedCount;

              if (index >= offset && index < offset + failedCount) {
                return _sectionItemBuilder(
                  context,
                  const ValueKey('failed'),
                  data!.statusMap!.failed!,
                  index - offset,
                  context.l10n!.failed,
                  failedExpanded,
                );
              }
              return const SizedBox.shrink();
            },
            itemCount: itemCount,
          ),
        ),
        refresh: () => ref.invalidate(updateSummaryProvider),
      ),
    );
  }

  int _buildSectionItemCount({
    List<Manga>? list,
    bool expanded = false,
  }) {
    var itemCount = 0;
    if (list?.isNotEmpty == true) {
      itemCount++;
      if (expanded) {
        itemCount += list!.length;
      }
    }
    return itemCount;
  }

  Widget _sectionItemBuilder(
    BuildContext context,
    Key? key,
    List<Manga> list,
    int index,
    String title,
    ValueNotifier<bool> expanded,
  ) {
    if (index == 0) {
      return UpdateStatusExpansionTileV2(
        key: key,
        mangas: list,
        title: title,
        expanded: expanded,
      );
    }
    final i = index - 1;
    final e = list[i];
    return MangaCoverListTile(
      manga: e,
      showCountBadges: true,
      onPressed: () => context.push(
        Routes.getManga(e.id!),
      ),
    );
  }
}

void showUpdateStatusSummaryBottomSheetV2(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => const UpdateStatusSummaryDialogV2(),
  );
}

class UpdateStatusExpansionTileV2 extends StatelessWidget {
  const UpdateStatusExpansionTileV2({
    super.key,
    required this.mangas,
    required this.title,
    required this.expanded,
  });

  final List<Manga> mangas;
  final String title;
  final ValueNotifier<bool> expanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text("$title (${mangas.length.padLeft()})"),
      initiallyExpanded: expanded.value,
      textColor: context.theme.indicatorColor,
      iconColor: context.theme.indicatorColor,
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      onExpansionChanged: (value) {
        expanded.value = value;
      },
    );
  }
}
