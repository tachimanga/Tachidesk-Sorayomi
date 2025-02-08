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
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/popup_Item_with_icon_child.dart';
import '../../../../widgets/search_field.dart';
import '../../../../widgets/shell/shell_screen.dart';
import '../../../sync/controller/sync_controller.dart';
import '../../../sync/widgets/sync_info_widget.dart';
import '../../data/manga_book_repository.dart';
import 'controller/history_controller.dart';
import 'widgets/history_clear_icon_button.dart';
import 'widgets/history_descriptive_list_tile.dart';
import 'widgets/incognito_icon_button.dart';

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaListSrc = ref.watch(historyListProvider);
    final mangaList = ref.watch(historyListFilterProvider);
    final toast = ref.read(toastProvider(context));
    final showSearch = useState(false);

    refresh() => ref.refresh(historyListProvider.future);

    useEffect(() {
      if (!mangaListSrc.isLoading) refresh();
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
      mangaList.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [mangaList]);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.history),
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
                    initialText: ref.read(historyMangaQueryProvider),
                    onChanged: (val) => ref
                        .read(historyMangaQueryProvider.notifier)
                        .update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
            ],
          ),
        ),
        centerTitle: true,
        leading: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SyncInfoWidget(),
            IncognitoIconButton(),
          ],
        ),
        leadingWidth: 56 /*_kLeadingWidth*/ * 2,
        actions: [
          IconButton(
            onPressed: () => showSearch.value = true,
            icon: const Icon(Icons.search_rounded),
          ),
          HistoryClearIconButton(
            refresh: refresh,
          ),
        ],
      ),
      body: mangaList.showUiWhenData(
        context,
        (data) {
          if (data.isBlank) {
            return Emoticons(
              text: context.l10n!.history_is_empty,
              button: TextButton(
                onPressed: refresh,
                child: Text(context.l10n!.refresh),
              ),
            );
          }
          return RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                controller: mainPrimaryScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: data?.length ?? 0,
                itemBuilder: (context, index) => HistoryDescriptiveListTile(
                  manga: data![index],
                  onPressed: () {
                    if (data[index].id != null) {
                      context.push(Routes.getManga(
                        data[index].id!,
                      ));
                    }
                  },
                  popupItems: [
                    PopupMenuItem(
                      child: PopupItemWithIconChild(
                        icon: const Icon(Icons.delete),
                        label: Text(context.l10n!.remove),
                      ),
                      onTap: () async {
                        final manga = data![index];
                        if (manga.id != null) {
                          (await AsyncValue.guard(
                            () => ref
                                .read(mangaBookRepositoryProvider)
                                .batchDeleteHistory([manga.id!]),
                          ))
                              .showToastOnError(toast);
                          await refresh();
                        }
                      },
                    ),
                  ],
                ),
              ));
        },
        refresh: refresh,
      ),
    );
  }
}
