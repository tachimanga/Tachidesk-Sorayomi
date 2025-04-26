// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/colored_safe_area.dart';
import '../../../../../widgets/confirm_dialog.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../../widgets/premium_required_tile.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../source/controller/source_custom_filter_controller.dart';
import '../../source/domain/source_meta_model.dart';
import '../controller/source_manga_controller.dart';
import 'filter_to_widget.dart';

class ShowSourceMangaFilter extends HookConsumerWidget {
  const ShowSourceMangaFilter({
    super.key,
    required this.sourceType,
    required this.sourceId,
    required this.controller,
  });
  final SourceType sourceType;
  final String sourceId;
  final PagingController<int, Manga> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = sourceMangaFilterListProvider(sourceId);
    final filterListValue = ref.watch(filtersProvider);

    final customFiltersProvider =
        sourceCustomFiltersWithSourceIdProvider(sourceId: sourceId);
    final customFilters = ref.watch(customFiltersProvider);

    final filters = useState(filterListValue.valueOrNull);

    useEffect(() {
      final v = filterListValue.valueOrNull;
      if (v != null) {
        filters.value = v;
      }
      return;
    }, [filterListValue]);

    // load source filters
    final refreshTimer = useRef<Timer?>(null);
    final filtersChangedByUser = useRef(false);
    useEffect(() {
      if (filterListValue.valueOrNull == null) {
        Future(() {
          if (context.mounted) {
            ref.read(filtersProvider.notifier).loadAndReset();
            refreshTimer.value = Timer(
              const Duration(milliseconds: 2000),
              () {
                log("[Filters]auto refresh filters");
                if (context.mounted && !filtersChangedByUser.value) {
                  ref.read(filtersProvider.notifier).loadAndReset();
                }
              },
            );
          }
        });
      }
      return () {
        refreshTimer.value?.cancel();
      };
    }, []);

    return ColoredSafeArea(
        child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kAppBarBottomHeight),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton(
                onPressed: () async {
                  await ref.read(filtersProvider.notifier).loadAndReset();
                },
                child: Text(context.l10n!.reset),
              ),
              const Spacer(),
              TextButton(
                onPressed: sourceType == SourceType.filter
                    ? () {
                        final filters =
                            ref.read(filtersProvider.notifier).getAppliedFilter;
                        showDialog(
                          context: context,
                          builder: (context) => SourceFilterSaveDialog(
                            sourceId: sourceId,
                            filters: filters,
                          ),
                        );
                        logEvent3("SOURCE:FILTER:SAVE:DIALOG");
                      }
                    : null,
                child: Text(context.l10n!.save),
              ),
              SizedBox(width: 5),
              FilledButton(
                onPressed: () {
                  if (filters.value == null) {
                    return;
                  }
                  ref
                      .read(filtersProvider.notifier)
                      .updateFilter(filters.value);
                  if (sourceType == SourceType.filter) {
                    context.pop();
                    controller.refresh();
                  } else {
                    context.pushReplacement(
                      Routes.getSourceManga(sourceId, SourceType.filter),
                    );
                  }
                },
                child: Text(context.l10n!.filter),
              ),
            ],
          ),
        ),
      ),
      body: filters.value == null
          ? CenterCircularProgressIndicator()
          : CustomScrollView(
              slivers: [
                if (customFilters?.isNotEmpty == true) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: KEdgeInsets.h16.size,
                      child: _buildSavedSearchWidget(context, customFilters!),
                    ),
                  ),
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filter = filters.value![index];
                      return FilterToWidget(
                        key: ValueKey("Filter-${filter.filterState?.name}"),
                        filter: filter,
                        onChanged: (value) {
                          filtersChangedByUser.value = true;
                          filters.value = ([...filters.value!]..replaceRange(
                              index,
                              index + 1,
                              [value],
                            ));
                        },
                      );
                    },
                    childCount: filters.value!.length,
                  ),
                ),
              ],
            ),
    ));
  }

  Widget _buildSavedSearchWidget(
      BuildContext context, List<SourceCustomFilter> customFilters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: KEdgeInsets.h4.size,
          child: Text(context.l10n!.saved_searches,
              style: context.textTheme.bodySmall),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: customFilters
                .map(
                  (e) => Padding(
                    padding: KEdgeInsets.h4.size,
                    child: SourceFilterChip(
                      sourceId: sourceId,
                      sourceType: sourceType,
                      filter: e,
                      controller: controller,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: KEdgeInsets.h4.size,
          child: Text(
            context.l10n!.long_press_to_delete,
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class SourceFilterChip extends HookConsumerWidget {
  const SourceFilterChip({
    super.key,
    required this.sourceId,
    required this.sourceType,
    required this.filter,
    required this.controller,
  });

  final String sourceId;
  final SourceType sourceType;
  final SourceCustomFilter filter;
  final PagingController<int, Manga> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = sourceMangaFilterListProvider(sourceId);
    return InkWell(
      onTap: () async {
        ref.read(filtersProvider.notifier).applyChangeToFilter(filter.filters);
        if (sourceType == SourceType.filter) {
          context.pop();
          controller.refresh();
        } else {
          context.pushReplacement(
            Routes.getSourceManga(sourceId, SourceType.filter),
          );
        }
        logEvent3("SOURCE:FILTER:APPLY");
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => SourceFilterDeleteDialog(
            sourceId: sourceId,
            filter: filter,
          ),
        );
        logEvent3("SOURCE:FILTER:DELETE:DIALOG");
      },
      child: Chip(
        label: Text(filter.title ?? ""),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(4.0),
      ),
    );
  }
}

class SourceFilterSaveDialog extends HookConsumerWidget {
  const SourceFilterSaveDialog({
    super.key,
    required this.sourceId,
    required this.filters,
  });

  final String sourceId;
  final List<Map<String, dynamic>> filters;

  void _update(String title, WidgetRef ref) async {
    final customFiltersProvider =
        sourceCustomFiltersWithSourceIdProvider(sourceId: sourceId);
    final filter = SourceCustomFilter(title: title, filters: filters);
    ref.read(customFiltersProvider.notifier).insert(filter);
    logEvent3("SOURCE:FILTER:SAVE:CONFIRM");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: "");

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final requiredPremium = !purchaseGate && !testflightFlag;

    return AlertDialog(
      title: Text(context.l10n!.save_query_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            autofocus: true,
            controller: controller,
            onSubmitted: (value) {
              if (requiredPremium) {
                return;
              }
              if (value.isEmpty) {
                return;
              }
              _update(controller.text, ref);
              context.pop();
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: context.l10n!.save_query_hint,
            ),
          ),
          if (requiredPremium) ...[
            SizedBox(height: 10),
            const PremiumRequiredTile(),
          ],
        ],
      ),
      actions: [
        const PopButton(),
        ElevatedButton(
          onPressed: requiredPremium
              ? null
              : () {
                  if (controller.text.isEmpty) {
                    return;
                  }
                  _update(controller.text, ref);
                  context.pop();
                },
          child: Text(context.l10n!.save),
        ),
      ],
    );
  }
}

class SourceFilterDeleteDialog extends HookConsumerWidget {
  const SourceFilterDeleteDialog({
    super.key,
    required this.sourceId,
    required this.filter,
  });

  final String sourceId;
  final SourceCustomFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customFiltersProvider =
        sourceCustomFiltersWithSourceIdProvider(sourceId: sourceId);
    return ConfirmDialog(
      title: Text(context.l10n!.delete_query_title),
      content: Text(context.l10n!.delete_query_content(filter.title ?? "")),
      onConfirm: () async {
        context.pop();
        ref.read(customFiltersProvider.notifier).remove(filter);
        logEvent3("SOURCE:FILTER:DELETE:CONFIRM");
      },
    );
  }
}
