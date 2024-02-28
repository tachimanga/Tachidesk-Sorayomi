// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../domain/migrate/migrate_model.dart';
import 'controller/migrate_controller.dart';
import 'widgets/migrate_manga_list_tile.dart';

class MigrateSourceDetailScreen extends HookConsumerWidget {
  const MigrateSourceDetailScreen(
      {super.key, required this.sourceId, this.migrateSource});
  final String sourceId;
  final MigrateSource? migrateSource;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaList =
        ref.watch(migrateMangaListFilterProvider(sourceId: sourceId));

    final source = migrateSource?.source;
    final localSource = source?.lang?.code == 'localsourcelang';
    final showSearch = useState(false);

    refresh() =>
        ref.refresh(migrateMangaListProvider(sourceId: sourceId).future);

    useEffect(() {
      mangaList.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [mangaList]);

    return Scaffold(
      appBar: AppBar(
        title: localSource
            ? Text(context.l10n!.local_source)
            : Text(source?.displayName ?? source?.name ?? ""),
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSizeV2(
            showTextField: showSearch.value,
          ),
          child: Column(
            children: [
              if (showSearch.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: SearchField(
                    initialText: ref.read(migrateMangaQueryProvider),
                    onChanged: (val) => ref
                        .read(migrateMangaQueryProvider.notifier)
                        .update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showSearch.value = true,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: mangaList.showUiWhenData(
        context,
        (data) {
          if (data.isEmpty) {
            return Emoticons(
              text: context.l10n!.noMangaFound,
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
              itemBuilder: (context, index) => MigrateMangaListTile(
                manga: data[index],
              ),
            ),
          );
        },
        refresh: refresh,
      ),
    );
  }
}
