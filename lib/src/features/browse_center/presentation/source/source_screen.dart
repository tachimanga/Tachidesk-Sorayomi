// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/language_list.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/locale_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../settings/presentation/browse/widgets/mutil_repo_setting/repo_help_button.dart';
import '../extension/controller/extension_controller.dart';
import 'controller/source_controller.dart';
import 'widgets/source_list_tile.dart';

class SourceScreen extends HookConsumerWidget {
  const SourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final sourceMapData = ref.watch(sourceMapFilteredProvider);
    final sourceMap = {...?sourceMapData.valueOrNull};
    final localSource = sourceMap.remove("localsourcelang");
    final lastUsed = sourceMap.remove("lastUsed");

    final emptyRepo = ref.watch(emptyRepoProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);

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

    refresh() => ref.refresh(sourceListProvider.future);
    useEffect(() {
      if (!sourceMapData.isLoading) refresh();
      return;
    }, []);

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
            slivers: [
              if (lastUsed.isNotBlank) ...[
                SliverToBoxAdapter(
                  child: ListTile(
                    title: Text(languageMap["lastUsed"]?.localizedDisplayName(context) ?? ""),
                  ),
                ),
                SliverToBoxAdapter(
                    child: SourceListTile(
                  source: lastUsed!.first,
                  pinSourceIdSet: pinSourceIdSet,
                ))
              ],
              for (final k in sourceMapKeys) ...[
                if (sourceMap[k].isNotBlank) ...[
                  SliverToBoxAdapter(
                    child:
                        ListTile(title: Text(languageMap[k]?.localizedDisplayName(context) ?? k)),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SourceListTile(
                        source: sourceMap[k]![index],
                        pinSourceIdSet: pinSourceIdSet,
                      ),
                      childCount: sourceMap[k]?.length,
                    ),
                  )
                ]
              ],
              if (localSource.isNotBlank) ...[
                SliverToBoxAdapter(
                  child: ListTile(
                    title:
                        Text(languageMap["localsourcelang"]?.localizedDisplayName(context) ?? ""),
                  ),
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
