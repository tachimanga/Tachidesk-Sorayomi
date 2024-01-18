// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
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
import '../../domain/extension/extension_model.dart';
import 'controller/extension_controller.dart';
import 'widgets/extension_list_tile.dart';

class ExtensionScreen extends HookConsumerWidget {
  const ExtensionScreen({super.key, this.repoId});

  final int? repoId;

  List<Widget> extensionSet({
    Key? key,
    required String title,
    required List<Extension>? extensions,
    required AsyncCallback refresh,
  }) {
    if (extensions.isBlank) return <Widget>[];
    return [
      SliverToBoxAdapter(
        child: ListTile(
          title: Text(title),
        ),
      ),
      SliverList(
        key: key,
        delegate: SliverChildBuilderDelegate(
          (context, index) => ExtensionListTile(
            key: ValueKey(extensions[index].extensionId),
            extension: extensions[index],
            refresh: refresh,
            showRepoName: repoId == null,
          ),
          childCount: extensions!.length,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionMapData = repoId != null
        ? ref.watch(
            extensionMapFilteredAndQueriedAndRepoIdProvider(repoId: repoId!))
        : ref.watch(extensionMapFilteredAndQueriedProvider);
    final extensionMap = {...?extensionMapData.valueOrNull};
    final installed = extensionMap.remove("installed");
    final update = extensionMap.remove("update");
    //final all = extensionMap.remove("all");

    final preferLocales = ref.watch(sysPreferLocalesProvider) + ['all', 'en'];
    final extensionMapKeys = [];
    if (extensionMap.isNotEmpty) {
      final left = [...extensionMap.keys];
      //print("before $left");
      for (final code in preferLocales) {
        if (extensionMap.containsKey(code)) {
          extensionMapKeys.add(code);
          left.remove(code);
        }
      }
      extensionMapKeys.addAll(left);
      //print("after $extensionMapKeys");
    }

    final emptyRepo = ref.watch(emptyRepoProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);

    refresh() => ref.refresh(extensionProvider.future);
    useEffect(() {
      if (!extensionMapData.isLoading) refresh();
      return;
    }, []);

    useEffect(() {
      extensionMapData.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [extensionMapData]);

    return extensionMapData.showUiWhenData(
      context,
      (data) => (extensionMap.isEmpty && installed.isBlank && update.isBlank)
          ? Emoticons(
              text: context.l10n!.extensionListEmpty,
              button: TextButton(
                onPressed: refresh,
                child: Text(context.l10n!.refresh),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.refresh(extensionProvider.future),
              child: CustomScrollView(
                slivers: [
                  if (update.isNotBlank)
                    ...extensionSet(
                      key: const ValueKey("update"),
                      title: languageMap["update"]?.localizedDisplayName(context) ?? "",
                      extensions: update,
                      refresh: refresh,
                    ),
                  if (installed.isNotBlank)
                    ...extensionSet(
                      key: const ValueKey("installed"),
                      title: languageMap["installed"]?.localizedDisplayName(context) ?? "",
                      extensions: installed,
                      refresh: refresh,
                    ),
                  /*
                  if (all.isNotBlank)
                    ...extensionSet(
                      key: const ValueKey("all"),
                      title: languageMap["all"]?.displayName ?? "",
                      extensions: all,
                      refresh: refresh,
                    ),
                  */
                  for (final k in extensionMapKeys)
                    ...extensionSet(
                      key: ValueKey(k),
                      title: languageMap[k]?.localizedDisplayName(context) ?? k,
                      extensions: extensionMap[k],
                      refresh: refresh,
                    ),
                  if (emptyRepo) ...const [
                    SliverToBoxAdapter(
                      child: RepoHelpButton(
                        icon: false,
                        source: "EXT_BOTTOM",
                      ),
                    ),
                  ]
                ],
              ),
            ),
      refresh: refresh,
    );
  }
}
