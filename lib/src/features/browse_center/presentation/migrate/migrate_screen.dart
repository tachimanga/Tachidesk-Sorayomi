// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import 'controller/migrate_controller.dart';
import 'widgets/migrate_source_list_tile.dart';

class MigrateScreen extends HookConsumerWidget {
  const MigrateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceListSrc = ref.watch(migrateSourceListProvider);
    final sourceList = ref.watch(migrateSourceListFilterProvider);

    refresh() => ref.refresh(migrateSourceListProvider.future);
    useEffect(() {
      if (!sourceListSrc.isLoading) {
        refresh();
      }
      return;
    }, []);

    useEffect(() {
      sourceListSrc.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [sourceListSrc]);

    return sourceList.showUiWhenData(
      context,
      (data) {
        if (data.isEmpty) {
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
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) => MigrateSourceListTile(
              migrateSource: data[index],
            ),
          ),
        );
      },
      refresh: refresh,
    );
  }
}
