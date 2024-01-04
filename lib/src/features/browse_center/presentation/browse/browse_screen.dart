// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/search_field.dart';
import '../extension/controller/extension_controller.dart';
import '../extension/extension_screen.dart';
import '../extension/widgets/extension_language_filter_dialog.dart';
import '../extension/widgets/install_extension_file.dart';
import '../source/controller/source_query_controller.dart';
import '../source/source_screen.dart';
import '../source/widgets/source_language_filter.dart';

class BrowseScreen extends HookConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);
    useListenable(tabController);
    final key = useMemoized(() => GlobalKey());
    final showSearch = useState(false);
    final magic = ref.watch(getMagicProvider);
    final extensionUpdate = ref.watch(extensionUpdateProvider);
    final extensionUpdateCount =
        extensionUpdate.valueOrNull?.isGreaterThan(0) == true
            ? extensionUpdate.value!
            : 0;
    final emptyRepo = ref.watch(emptyRepoProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final toast = ref.watch(toastProvider(context));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.browse),
        centerTitle: true,
        actions: emptyRepo
            ? [
                IconButton(
                  onPressed: () => launchUrlInWeb(
                    context,
                    userDefaults.getString("config.helpUrl") ??
                        AppUrls.addRepo.url,
                    toast,
                  ),
                  icon: const Icon(Icons.help),
                ),
              ]
            : [
                IconButton(
                  onPressed: () => showSearch.value = true,
                  icon: const Icon(Icons.search_rounded),
                ),
                if (tabController.index == 1 && magic.a6 == true) ...[
                  const InstallExtensionFile(),
                ],
                if (tabController.index == 0 && magic.b7 == true) ...[
                  IconButton(
                    onPressed: () {
                      context.push(Routes.getGlobalSearch(""));
                    },
                    icon: const Icon(Icons.travel_explore_rounded),
                  ),
                ],
                IconButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => tabController.index == 0
                        ? const SourceLanguageFilter()
                        : const ExtensionLanguageFilterDialog(),
                  ),
                  icon: const Icon(Icons.translate_rounded),
                ),
              ],
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSize([true, showSearch.value]),
          child: Column(
            children: [
              TabBar(
                dividerColor: Colors.transparent,
                isScrollable: context.isTablet,
                controller: tabController,
                tabs: [
                  Tab(text: context.l10n!.sources),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tab(text: context.l10n!.extensions),
                        if (extensionUpdateCount > 0) ...[
                          const SizedBox(width: 2),
                          Badge(label: Text("$extensionUpdateCount"))
                        ]
                      ],
                    ),
                  )
                ],
              ),
              if (showSearch.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: tabController.index == 0
                      ? SearchField(
                          key: const ValueKey(0),
                          onChanged: (val) => ref
                              .read(sourceQueryProvider.notifier)
                              .update(val),
                          onSubmitted: (value) {
                            if (value.isNotBlank) {
                              ref
                                  .read(sourceQueryProvider.notifier)
                                  .update(null);
                              context.push(Routes.getGlobalSearch(value));
                            }
                          },
                          onClose: () => showSearch.value = false,
                        )
                      : SearchField(
                          key: const ValueKey(1),
                          initialText: ref.read(extensionQueryProvider),
                          onChanged: (val) => ref
                              .read(extensionQueryProvider.notifier)
                              .update(val),
                          onClose: () => showSearch.value = false,
                        ),
                ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        key: key,
        controller: tabController,
        children: const [
          SourceScreen(),
          ExtensionScreen(),
        ],
      ),
    );
  }
}
