// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_constants.dart';
import '../../../../constants/language_list.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/locale_providers.dart';
import '../../../../icons/icomoon_icons.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/shell/shell_screen.dart';
import '../../../settings/presentation/browse/widgets/mutil_repo_setting/repo_help_button.dart';
import '../../../sync/controller/sync_controller.dart';
import '../extension/controller/extension_controller.dart';
import 'controller/source_controller.dart';
import 'widgets/source_list_tile.dart';

class SourceScreen extends HookConsumerWidget {
  const SourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final sourceMapData = ref.watch(sourceMapLangAndKeywordFilteredProvider);
    final sourceMap = {...?sourceMapData.valueOrNull};
    final localSource = sourceMap.remove("localsourcelang");
    final lastUsed = sourceMap.remove("lastUsed");

    final emptyRepo = ref.watch(emptyRepoProvider);

    final pinSourceIdList = ref.watch(pinSourceIdListProvider);
    final pinSourceIdSet = {...?pinSourceIdList};

    final preferLocales =
        ['pinned'] + ref.watch(sysPreferLocalesProvider) + ['all', 'en'];
    final sourceMapKeys = [];
    if (sourceMap.isNotEmpty) {
      final left = [...sourceMap.keys];
      //print("before $left");
      for (final code in preferLocales) {
        if (sourceMap.containsKey(code)) {
          sourceMapKeys.add(code);
          left.remove(code);
        }
      }
      sourceMapKeys.addAll(left);
      //print("after $sourceMapKeys");
    }

    final reorderState = useState(false);

    refresh() => ref.refresh(sourceListProvider.future);
    useEffect(() {
      if (!sourceMapData.isLoading) refresh();
      return;
    }, []);

    final syncRefreshSignal = ref.watch(syncRefreshSignalProvider);
    useEffect(() {
      if (syncRefreshSignal) {
        refresh();
      }
      return;
    }, [syncRefreshSignal]);

    useEffect(() {
      sourceMapData.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [sourceMapData]);

    return sourceMapData.showUiWhenData(
      context,
      (data) {
        if ((sourceMap.isEmpty && localSource.isBlank && lastUsed.isBlank)) {
          return Emoticons(
            text: context.l10n!.noSourcesFound,
            button: TextButton(
              onPressed: refresh,
              child: Text(context.l10n!.refresh),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: CustomScrollView(
            controller: mainPrimaryScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (lastUsed.isNotBlank) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(code: "lastUsed"),
                ),
                SliverToBoxAdapter(
                  child: SourceListTile(
                    source: lastUsed!.first,
                    pinSourceIdSet: pinSourceIdSet,
                  ),
                )
              ],
              for (final k in sourceMapKeys) ...[
                if (sourceMap[k].isNotBlank) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      code: k,
                      reorderState: k == "pinned" ? reorderState : null,
                    ),
                  ),
                  (k == "pinned" && reorderState.value)
                      ? SliverReorderableList(
                          itemBuilder: (context, index) => SourceListTile(
                            key: ValueKey(sourceMap[k]![index].id),
                            source: sourceMap[k]![index],
                            pinSourceIdSet: pinSourceIdSet,
                            trailing: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icomoon.reorder2),
                            ),
                          ),
                          itemCount: sourceMap[k]!.length,
                          onReorder: (int oldIndex, int newIndex) {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            final items =
                                sourceMap[k]!.map((e) => e.id!).toList();
                            final item = items.removeAt(oldIndex);
                            items.insert(newIndex, item);
                            ref
                                .read(pinSourceIdListProvider.notifier)
                                .update(items);
                          },
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => SourceListTile(
                              source: sourceMap[k]![index],
                              pinSourceIdSet: pinSourceIdSet,
                            ),
                            childCount: sourceMap[k]?.length,
                          ),
                        ),
                ]
              ],
              if (localSource.isNotBlank) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader(code: "localsourcelang"),
                ),
                SliverToBoxAdapter(
                  child: SourceListTile(
                    source: localSource!.first,
                    pinSourceIdSet: pinSourceIdSet,
                  ),
                )
              ],
              if (magic.b9 && emptyRepo) ...[
                const SliverToBoxAdapter(
                  child: RepoHelpButton(
                    icon: false,
                    source: "SRC_BOTTOM",
                  ),
                ),
              ]
            ],
          ),
        );
      },
      refresh: refresh,
    );
  }
}

class SectionHeader extends ConsumerWidget {
  const SectionHeader({
    super.key,
    required this.code,
    this.reorderState,
  });

  final String code;
  final ValueNotifier<bool>? reorderState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = languageMap[code]?.localizedDisplayName(context) ?? code;
    if (reorderState != null) {
      return ListTile(
        title: Row(
          children: [
            Flexible(
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
            reorderState!.value
                ? TextButton(
                    onPressed: () => reorderState!.value = false,
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(context.l10n!.done_label),
                  )
                : IconButton(
                    icon: const Icon(Icomoon.settings2),
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => reorderState!.value = true,
                  ),
          ],
        ),
      );
    }
    return ListTile(title: Text(title));
  }
}
