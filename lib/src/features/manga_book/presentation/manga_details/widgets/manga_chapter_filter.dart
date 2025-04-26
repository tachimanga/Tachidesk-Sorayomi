// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../icons/icomoon_icons.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/custom_checkbox_list_tile.dart';
import '../../../../../widgets/premium_required_tile.dart';
import '../../../../../widgets/tristate_checkbox_list_tile.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/manga/manga_model.dart';
import '../controller/manga_chapter_controller.dart';
import '../controller/manga_details_controller.dart';

class MangaChapterFilter extends HookConsumerWidget {
  const MangaChapterFilter({
    super.key,
    required this.mangaId,
  });

  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    // unread filter
    final filterUnreadWithMangaIdProvider =
        mangaChapterFilterUnreadWithMangaIdProvider(mangaId: mangaId);
    final filterUnreadWithMangaId = ref.watch(filterUnreadWithMangaIdProvider);

    // bookmarked filter
    final filterBookmarkedWithMangaIdProvider =
        mangaChapterFilterBookmarkedWithMangaIdProvider(mangaId: mangaId);
    final filterBookmarkedWithMangaId =
        ref.watch(filterBookmarkedWithMangaIdProvider);

    // downloaded filter
    final filterDownloadedWithMangaIdProvider =
        mangaChapterFilterDownloadedWithMangaIdProvider(mangaId: mangaId);
    final filterDownloadedWithMangaId =
        ref.watch(filterDownloadedWithMangaIdProvider);

    // scanlator filter
    final mangaScanlatorList =
        ref.watch(mangaScanlatorListProvider(mangaId: mangaId));

    final realScanlatorMetaProvider =
        mangaChapterFilterScanlatorProvider(mangaId: mangaId);
    final fakeScanlatorMetaProvider =
        fakeMangaChapterFilterScanlatorProvider(mangaId: mangaId);
    final scanlatorMetaProvider = purchaseGate || testflightFlag
        ? realScanlatorMetaProvider
        : fakeScanlatorMetaProvider;
    final scanlatorMeta = ref.watch(scanlatorMetaProvider);
    final scanlatorType = ScanlatorFilterType.safeFromIndex(scanlatorMeta.type);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TriCheckboxListTile(
            title: Text(context.l10n!.unread),
            value: filterUnreadWithMangaId,
            tristate: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.theme.indicatorColor,
            onChanged: (value) {
              ref.read(filterUnreadWithMangaIdProvider.notifier).update(value);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: TriCheckboxListTile(
            title: Text(context.l10n!.bookmarked),
            value: filterBookmarkedWithMangaId,
            tristate: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.theme.indicatorColor,
            onChanged: (value) {
              ref
                  .read(filterBookmarkedWithMangaIdProvider.notifier)
                  .update(value);
            },
          ),
        ),
        SliverToBoxAdapter(
          child: TriCheckboxListTile(
            title: Text(context.l10n!.downloaded),
            value: filterDownloadedWithMangaId,
            tristate: true,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.theme.indicatorColor,
            onChanged: (value) {
              ref
                  .read(filterDownloadedWithMangaIdProvider.notifier)
                  .update(value);
            },
          ),
        ),
        if (mangaScanlatorList.isNotBlank && mangaScanlatorList.length > 1) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                context.l10n!.scanlators,
                style: context.textTheme.labelLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: SegmentedButton<ScanlatorFilterType>(
                segments: [
                  for (final type in ScanlatorFilterType.values)
                    ButtonSegment<ScanlatorFilterType>(
                      value: type,
                      label: Text(type.toLocale(context)),
                      enabled: true,
                    ),
                ],
                showSelectedIcon: true,
                selected: {scanlatorType},
                onSelectionChanged: (Set<ScanlatorFilterType> set) {
                  logEvent3("SCANLATOER:SET:${set.first.name}");
                  var meta = scanlatorMeta.copyWith(type: set.first.index);
                  meta = initPriorityListIfNeeded(meta, mangaScanlatorList);
                  if (purchaseGate || testflightFlag) {
                    ref.read(realScanlatorMetaProvider.notifier).update(meta);
                  } else {
                    if (scanlatorType == ScanlatorFilterType.priority) {
                      logEvent3("SCANLATOER:SET:PRIORITY:GATE");
                    }
                    ref.read(fakeScanlatorMetaProvider.notifier).update(meta);
                  }
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ScanlatorFilterDescription(
              type: scanlatorType,
            ),
          ),
          if (!purchaseGate &&
              !testflightFlag &&
              scanlatorType == ScanlatorFilterType.priority) ...[
            SliverToBoxAdapter(
              child: const PremiumRequiredTile(),
            ),
          ],
          scanlatorType == ScanlatorFilterType.filter
              ? ScanlatorSelectListView(
                  mangaId: mangaId,
                  mangaScanlatorList: mangaScanlatorList,
                )
              : ScanlatorPriorityListView(
                  mangaId: mangaId,
                  mangaScanlatorList: mangaScanlatorList,
                ),
        ],
      ],
    );
  }

  ScanlatorMeta initPriorityListIfNeeded(
    ScanlatorMeta meta,
    List<Pair<String, int>> mangaScanlatorList,
  ) {
    if (meta.type != ScanlatorFilterType.priority.index) {
      return meta;
    }
    if (meta.priority?.isNotEmpty == true) {
      return meta;
    }
    Set<String> selected = {...?meta.list};
    List<String> priorityList = [];
    for (final scanlator in mangaScanlatorList) {
      if (selected.contains(scanlator.first)) {
        priorityList.add(scanlator.first);
      }
    }
    for (final scanlator in mangaScanlatorList) {
      if (!selected.contains(scanlator.first)) {
        priorityList.add(scanlator.first);
      }
    }
    return meta.copyWith(priority: priorityList);
  }
}

class ScanlatorFilterDescription extends ConsumerWidget {
  const ScanlatorFilterDescription({
    super.key,
    required this.type,
  });

  final ScanlatorFilterType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var text = "";
    if (type == ScanlatorFilterType.filter) {
      text = context.l10n!.scanlator_filter_description;
    } else if (type == ScanlatorFilterType.priority) {
      text = context.l10n!.scanlator_priority_description;
    }
    return Padding(
      padding: KEdgeInsets.h16v4.size,
      child: Text(
        text,
        style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}

class ScanlatorSelectListView extends ConsumerWidget {
  const ScanlatorSelectListView({
    super.key,
    required this.mangaId,
    required this.mangaScanlatorList,
  });

  final String mangaId;
  final List<Pair<String, int>> mangaScanlatorList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanlatorMeta =
        ref.watch(mangaChapterFilterScanlatorProvider(mangaId: mangaId));
    final selectedScanlators = scanlatorMeta.list ?? [];
    final selectedScanlatorSet = {...selectedScanlators};
    final scanlatorFilterProvider =
        mangaChapterFilterScanlatorProvider(mangaId: mangaId);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(context.l10n!.allScanlators),
              value: selectedScanlatorSet.isEmpty,
              onChanged: (value) {
                if (value == true) {
                  final meta = scanlatorMeta.copyWith(
                    type: ScanlatorFilterType.filter.index,
                    list: [],
                  );
                  ref.read(scanlatorFilterProvider.notifier).update(meta);
                }
              },
            );
          }
          final scanlator = mangaScanlatorList[index - 1];
          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    scanlator.first,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 2),
                Badge(
                  label: Text("${scanlator.second}"),
                  textColor: context.textTheme.labelSmall?.color,
                  backgroundColor: Colors.grey.withOpacity(.2),
                )
              ],
            ),
            value: selectedScanlatorSet.contains(scanlator.first),
            onChanged: (value) {
              if (value == true) {
                selectedScanlatorSet.add(scanlator.first);
              } else {
                selectedScanlatorSet.remove(scanlator.first);
              }
              final meta = scanlatorMeta.copyWith(
                type: ScanlatorFilterType.filter.index,
                list: [...selectedScanlatorSet],
              );
              ref.read(scanlatorFilterProvider.notifier).update(meta);
            },
          );
        },
        childCount: mangaScanlatorList.length + 1,
      ),
    );
  }
}

class ScanlatorPriorityListView extends ConsumerWidget {
  const ScanlatorPriorityListView({
    super.key,
    required this.mangaId,
    required this.mangaScanlatorList,
  });

  final String mangaId;
  final List<Pair<String, int>> mangaScanlatorList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final realScanlatorMetaProvider =
        mangaChapterFilterScanlatorProvider(mangaId: mangaId);
    final fakeScanlatorMetaProvider =
        fakeMangaChapterFilterScanlatorProvider(mangaId: mangaId);
    final scanlatorMetaProvider = purchaseGate || testflightFlag
        ? realScanlatorMetaProvider
        : fakeScanlatorMetaProvider;

    final scanlatorMeta = ref.watch(scanlatorMetaProvider);

    final priorityList = [...?scanlatorMeta.priority];
    final prioritySet = {...priorityList};
    for (final scanlator in mangaScanlatorList) {
      if (!prioritySet.contains(scanlator.first)) {
        priorityList.add(scanlator.first);
      }
    }

    final mangaScanlatorMap = <String, int>{};
    for (final scanlator in mangaScanlatorList) {
      mangaScanlatorMap[scanlator.first] = scanlator.second;
    }

    return SliverReorderableList(
      itemBuilder: (context, index) {
        final scanlator = priorityList[index];
        final tile = ListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  scanlator,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2),
              Badge(
                label: Text("${mangaScanlatorMap[scanlator] ?? 0}"),
                textColor: context.textTheme.labelSmall?.color,
                backgroundColor: Colors.grey.withOpacity(.2),
              )
            ],
          ),
          trailing: ReorderableDragStartListener(
            index: index,
            child: const Icon(Icomoon.reorder2),
          ),
        );
        // fix https://github.com/flutter/flutter/issues/103318
        return Material(
          key: ValueKey(scanlator),
          color: Colors.transparent,
          child: tile,
        );
      },
      itemCount: priorityList.length,
      onReorder: (int oldIndex, int newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final list = [...priorityList];
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);
        final meta = scanlatorMeta.copyWith(
          type: ScanlatorFilterType.priority.index,
          priority: list,
        );
        if (purchaseGate || testflightFlag) {
          ref.read(realScanlatorMetaProvider.notifier).update(meta);
        } else {
          logEvent3("SCANLATOER:SET:PRIORITY:MOVE:GATE");
          ref.read(fakeScanlatorMetaProvider.notifier).update(meta);
        }
      },
    );
  }
}
