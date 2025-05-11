// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../settings/presentation/library/widgets/update_categories_setting_tile.dart';
import '../../../../settings/presentation/library/widgets/update_skip_titles_setting_tile.dart';
import '../../../data/updates/updates_repository.dart';
import '../../../domain/manga/manga_model.dart';
import '../../../domain/update_status/update_status_model.dart';
import '../../../widgets/update_status_fab.dart';
import '../../../widgets/update_status_popup_menu.dart';
import 'update_setting_dialog.dart';
import 'update_summary_manga_list_tile.dart';

class UpdateStatusSummaryDialogV3 extends HookConsumerWidget {
  const UpdateStatusSummaryDialogV3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusUpdate = ref.watch(updateSummaryProvider);
    final statusUpdateStream = ref.watch(updatesSocketProvider);
    final AsyncValue<UpdateStatus?> finalStatus =
        (statusUpdateStream.valueOrNull?.total.isGreaterThan(0)).ifNull()
            ? statusUpdateStream
            : statusUpdate;

    final expandedMap = useState({
      UpdateStatusEnum.RUNNING: true,
      UpdateStatusEnum.FAILED: true,
    });
    final skippedExpandedMap = useState(<JobErrorCode, bool>{});

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.updatesSummary),
        actions: const [
          UpdateStatusPopupMenu(showSummaryButton: false),
        ],
      ),
      body: finalStatus.showUiWhenData(
        context,
        (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(updateSummaryProvider.future),
          child: data == null || data.numberOfJobs == 0
              ? Emoticons(
                  text: context.l10n!.noUpdatesFound,
                  button: TextButton(
                    onPressed: () {
                      fireGlobalUpdate(ref);
                    },
                    child: Text(context.l10n!.refresh),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    ..._buildSlivers(
                      context,
                      data.statusMap,
                      data.failedInfo,
                      expandedMap,
                      skippedExpandedMap,
                    ),
                  ],
                ),
        ),
        refresh: () => ref.invalidate(updateSummaryProvider),
      ),
    );
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    UpdateStatusMap? map,
    Map<int, FailedInfo>? failedInfoMap,
    ValueNotifier<Map<UpdateStatusEnum, bool>> expandedMap,
    ValueNotifier<Map<JobErrorCode, bool>> skippedExpandedMap,
  ) {
    List<Widget> widgets = [];

    List<Manga> failedList = [];
    Map<JobErrorCode, List<Manga>> skippedMap = {};

    if (map?.failed?.isNotEmpty == true) {
      for (final manga in map!.failed!) {
        final failedInfo = failedInfoMap?[manga.id];
        final code = failedInfo?.errorCode ?? JobErrorCode.UPDATE_FAILED;
        if (code == JobErrorCode.UPDATE_FAILED) {
          failedList.add(manga);
        } else {
          skippedMap.putIfAbsent(code, () => []).add(manga);
        }
      }
    }

    for (final status in UpdateStatusEnum.values) {
      var list0 = status.fetchMangas(map);
      if (status == UpdateStatusEnum.FAILED) {
        list0 = failedList;
      } else if (status == UpdateStatusEnum.SKIPPED) {
        list0 = skippedMap.values.expand((list) => list).toList();
      }
      final list = list0;
      if (list?.isNotEmpty == true) {
        final expanded = expandedMap.value[status] ?? false;
        final header = SliverToBoxAdapter(
          child: UpdateStatusExpansionTileV3(
            key: ValueKey(status),
            status: status,
            length: list!.length,
            list: list,
            leading: status == UpdateStatusEnum.RUNNING
                ? MiniCircularProgressIndicator(padding: KEdgeInsets.a4.size)
                : Icon(status.toIconData()),
            title: status.toLocale(context),
            expanded: expanded,
            onChanged: (value) {
              expandedMap.value = {...expandedMap.value, status: value};
            },
          ),
        );
        widgets.add(header);

        if (expanded) {
          if (status != UpdateStatusEnum.SKIPPED) {
            final body = SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final e = list[index];
                  final failedInfo = failedInfoMap?[e.id];
                  return UpdateSummaryMangaListTile(
                    manga: e,
                    updateErrorMessage: failedInfo?.errorMessage,
                    onPressed: () => context.push(
                      Routes.getManga(e.id!),
                    ),
                  );
                },
                childCount: list.length,
              ),
            );
            widgets.add(body);
          } else {
            final slivers = _buildSkippedSlivers(
              context,
              skippedMap,
              skippedExpandedMap,
            );
            widgets.addAll(slivers);
          }
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildSkippedSlivers(
    BuildContext context,
    Map<JobErrorCode, List<Manga>> skippedMap,
    ValueNotifier<Map<JobErrorCode, bool>> expandedMap,
  ) {
    List<Widget> widgets = [];
    for (final code in JobErrorCode.values.sublist(1)) {
      final list = skippedMap[code];
      if (list?.isNotEmpty == true) {
        final expanded = expandedMap.value[code] ?? false;
        final header = SliverToBoxAdapter(
          child: SkippedExpansionTile(
            key: ValueKey(code),
            code: code,
            list: list!,
            title: code.toLocale(context),
            expanded: expanded,
            onChanged: (value) {
              expandedMap.value = {...expandedMap.value, code: value};
            },
          ),
        );
        final body = SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final e = list[index];
              return UpdateSummaryMangaListTile(
                manga: e,
                onPressed: () => context.push(
                  Routes.getManga(e.id!),
                ),
              );
            },
            childCount: expanded ? list.length : 0,
          ),
        );
        widgets.add(header);
        widgets.add(body);
      }
    }
    return widgets;
  }
}

void showUpdateStatusSummaryBottomSheetV3(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => const UpdateStatusSummaryDialogV3(),
  );
}

class UpdateStatusExpansionTileV3 extends ConsumerWidget {
  const UpdateStatusExpansionTileV3({
    super.key,
    required this.status,
    required this.leading,
    required this.title,
    required this.length,
    required this.expanded,
    required this.onChanged,
    this.list,
  });

  final UpdateStatusEnum status;
  final Widget leading;
  final String title;
  final int length;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final List<Manga>? list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);

    return ExpansionTile(
      leading: leading,
      tilePadding: kSettingPadding,
      title: Row(
        children: [
          Expanded(child: Text("$title (${length.padLeft()})")),
          if (status == UpdateStatusEnum.SKIPPED && magic.b7) ...[
            IconButton(
              icon: Icon(Icons.settings),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                logEvent3("UPDATE:summary:skipSetting");
                showDialog(
                  context: context,
                  builder: (context) => UpdateSettingDialog(
                    retryWhenDismiss: true,
                  ),
                );
              },
            ),
          ],
          if (status == UpdateStatusEnum.FAILED) ...[
            AsyncIconButton(
              icon: const Icon(Icons.replay),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                logEvent3("UPDATE:summary:retry:failed");
                await retryByCodes(ref, [JobErrorCode.UPDATE_FAILED.name]);
                await Future.delayed(Duration(seconds: 1));
              },
            ),
          ],
        ],
      ),
      initiallyExpanded: expanded,
      textColor: context.theme.indicatorColor,
      iconColor: context.theme.indicatorColor,
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      onExpansionChanged: onChanged,
    );
  }
}

class SkippedExpansionTile extends HookConsumerWidget {
  const SkippedExpansionTile({
    super.key,
    required this.title,
    required this.code,
    required this.list,
    required this.expanded,
    required this.onChanged,
  });

  final String title;
  final JobErrorCode code;
  final List<Manga> list;
  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running = useState(false);

    return ExpansionTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              "$title (${list.length.padLeft()})",
              style: context.textTheme.titleSmall,
            ),
          ),
          PopupMenuButton(
            style: ButtonStyle(visualDensity: VisualDensity.compact),
            shape: RoundedRectangleBorder(
              borderRadius: KBorderRadius.r16.radius,
            ),
            icon: Icon(Icons.more_vert_outlined),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: running.value
                    ? null
                    : () async {
                        running.value = true;
                        try {
                          logEvent3("UPDATE:summary:forceUpdateSkip");
                          await retryByCodes(ref, [code.name]);
                          await Future.delayed(Duration(seconds: 1));
                        } finally {
                          running.value = false;
                        }
                      },
                child: Text(context.l10n!.force_update),
              ),
              PopupMenuItem(
                onTap: () {
                  logEvent3("UPDATE:summary:skipMoreSetting");
                  showDialog(
                    context: context,
                    builder: (context) => UpdateSettingDialog(
                      retryWhenDismiss: true,
                    ),
                  );
                },
                child: Text(context.l10n!.settings),
              ),
            ],
          ),
        ],
      ),
      tilePadding: kSettingPadding,
      initiallyExpanded: expanded,
      textColor: context.theme.indicatorColor,
      iconColor: context.theme.indicatorColor,
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      onExpansionChanged: onChanged,
      visualDensity: VisualDensity.compact,
    );
  }
}
