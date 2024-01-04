// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';

import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../../widgets/pop_button.dart';
import '../source/controller/source_controller.dart';
import '../source/widgets/source_list_tile.dart';
import 'controller/extension_info_controller.dart';
import 'widgets/extension_descriptive_list_tile.dart';

class ExtensionInfoScreen extends HookConsumerWidget {
  const ExtensionInfoScreen({super.key, required this.pkgName});
  final String pkgName;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionInfo = ref.watch(extensionInfoProvider(pkgName: pkgName));
    final toast = ref.watch(toastProvider(context));
    final pinSourceIdList = ref.watch(pinSourceIdListProvider);
    final pinSourceIdSet = {...?pinSourceIdList};

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.extensions),
        actions: [
          if (extensionInfo.valueOrNull?.changelogUrl?.isNotEmpty == true)
            IconButton(
              onPressed: () => launchUrlInWeb(context,
                  extensionInfo.valueOrNull?.changelogUrl ?? "", toast),
              icon: const Icon(Icons.history_rounded),
            ),
          if (extensionInfo.valueOrNull?.readmeUrl?.isNotEmpty == true)
            IconButton(
              onPressed: () => launchUrlInWeb(
                  context, extensionInfo.valueOrNull?.readmeUrl ?? "", toast),
              icon: const Icon(Icons.help_rounded),
            ),
        ],
      ),
      body: extensionInfo.showUiWhenData(
        context,
        (data) {
          if (data.extension == null || data.sources?.isEmpty == true) {
            return Emoticons(
              text: context.l10n!.noSourcesFound,
            );
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ExtensionDescriptiveListTile(extension: data.extension!),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SourceListTile(
                    source: data.sources![index],
                    pinSourceIdSet: pinSourceIdSet,
                  ),
                  childCount: data.sources!.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
