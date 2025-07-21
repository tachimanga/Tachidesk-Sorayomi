// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../../../manga_book/presentation/updates/controller/update_controller.dart';
import '../../../manga_book/presentation/updates/widgets/update_status_list_tile.dart';
import '../../../manga_book/widgets/update_status_popup_menu.dart';
import '../../../sync/controller/sync_controller.dart';
import '../../../sync/widgets/sync_info_widget.dart';
import '../../domain/category/category_model.dart';
import '../category/controller/edit_category_controller.dart';
import 'category_manga_list.dart';
import 'controller/library_controller.dart';
import 'domain/select_key.dart';
import 'widgets/library_category_tab.dart';
import 'widgets/library_filter_icon_button.dart';
import 'widgets/library_manga_organizer.dart';
import 'widgets/library_select_icon_button.dart';
import 'widgets/multi_manga_action_bar.dart';

class LibraryScreen extends HookConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    final toast = ref.watch(toastProvider(context));
    final categoryList = ref.watch(categoryControllerProvider);
    final showSearch = useState(false);
    final showMangaCount = ref.watch(libraryShowMangaCountProvider);
    final showUpdateStatus = ref.watch(showUpdateStatusProvider);

    useEffect(() {
      if (!categoryList.isLoading) {
        ref.read(categoryControllerProvider.notifier).reloadCategories();
      }
      return;
    }, []);

    final syncRefreshSignal = ref.watch(syncRefreshSignalProvider);
    useEffect(() {
      if (syncRefreshSignal) {
        ref.read(categoryControllerProvider.notifier).reloadCategories();
      }
      return;
    }, [syncRefreshSignal]);

    useEffect(() {
      categoryList.showToastOnError(toast, withMicrotask: true);
      if (categoryList.valueOrNull?.isNotEmpty == true &&
          magic.b8 &&
          ref.read(markNeedAskRateProvider) == true) {
        Future(() {
          ref.read(markNeedAskRateProvider.notifier).update(false);
        });
        pipe.invokeMethod("ASK_RATE");
      }
      return;
    }, [categoryList]);

    final selectedMangeMap = useState<Map<SelectKey, Manga>?>(null);
    final readMode = selectedMangeMap.value == null;

    return categoryList.showUiWhenData(
      context,
      (data) => data.isBlank
          ? Emoticons(
              text: context.l10n!.noCategoriesFound,
              button: TextButton(
                onPressed: () => ref.refresh(categoryControllerProvider),
                child: Text(context.l10n!.refresh),
              ),
            )
          : DefaultTabController(
              length: data!.length,
              child: Scaffold(
                appBar: AppBar(
                  title: readMode
                      ? Text(context.l10n!.library)
                      : Text(context.l10n!
                          .numSelected(selectedMangeMap.value?.length ?? 0)),
                  centerTitle: readMode ? true : null,
                  leading: readMode
                      ? const SyncInfoWidget()
                      : IconButton(
                          onPressed: () => selectedMangeMap.value = null,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  bottom: PreferredSize(
                    preferredSize: kCalculateAppBarBottomSizeV2(
                      showTabBar: data.length.isGreaterThan(1),
                      showTextField: showSearch.value,
                      showUpdateStatus: showUpdateStatus,
                    ),
                    child: Column(
                      children: [
                        if (data.length.isGreaterThan(1))
                          TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.center,
                            tabs: data
                                .map((e) => LibraryCategoryTab(
                                      category: e,
                                      showMangaCount: showSearch.value ||
                                          showMangaCount == true,
                                    ))
                                .toList(),
                            dividerColor: Colors.transparent,
                          ),
                        if (showSearch.value)
                          Align(
                            alignment: Alignment.centerRight,
                            child: SearchField(
                              initialText: ref.read(libraryQueryProvider),
                              onChanged: (val) => ref
                                  .read(libraryQueryProvider.notifier)
                                  .update(val),
                              onClose: () => showSearch.value = false,
                            ),
                          ),
                        if (showUpdateStatus) const UpdateStatusListTile(),
                      ],
                    ),
                  ),
                  actions: readMode
                      ? [
                          IconButton(
                            onPressed: () => showSearch.value = true,
                            icon: const Icon(Icons.search_rounded),
                          ),
                          Builder(
                            builder: (context) => LibraryFilterIconButton(
                              icon: IconButton(
                                onPressed: () {
                                  _showLibraryFilter(context, data);
                                },
                                icon: const Icon(Icons.filter_list_rounded),
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              return UpdateStatusPopupMenu(
                                getCategory: () => data.isNotBlank
                                    ? data[
                                        DefaultTabController.of(context).index]
                                    : null,
                                onTapSelectManga: () {
                                  selectedMangeMap.value = {};
                                },
                                showRandomButton: true,
                              );
                            },
                          ),
                        ]
                      : [
                          LibrarySelectIconButton(
                            mode: SelectMode.between,
                            categories: data,
                            selectMangaMap: selectedMangeMap,
                          ),
                          LibrarySelectIconButton(
                            mode: SelectMode.all,
                            categories: data,
                            selectMangaMap: selectedMangeMap,
                          ),
                          LibrarySelectIconButton(
                            mode: SelectMode.invert,
                            categories: data,
                            selectMangaMap: selectedMangeMap,
                          ),
                        ],
                ),
                endDrawerEnableOpenDragGesture: false,
                endDrawer: context.isTablet
                    ? Drawer(
                        width: kDrawerWidth,
                        child: Builder(
                          builder: (context) {
                            final category =
                                data[DefaultTabController.of(context).index];
                            return LibraryMangaOrganizer(category: category);
                          },
                        ),
                      )
                    : null,
                bottomSheet: readMode
                    ? null
                    : Builder(
                        builder: (context) => MultiMangaActionBar(
                          afterOptionSelected: (Map<SelectKey, Manga>? prev) async {
                            _reloadListAfterAction(context, ref, data);
                          },
                          selectedMangaMap: selectedMangeMap,
                        ),
                      ),
                body: TabBarView(
                  children: data
                      .map((e) => CategoryMangaList(
                            categoryId: e.id ?? 0,
                            categoryCount: data.length,
                            selectMangaMap: selectedMangeMap,
                          ))
                      .toList(),
                ),
              ),
            ),
      refresh: () => ref.refresh(categoryControllerProvider),
      wrapper: (body) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n!.library),
          centerTitle: true,
        ),
        body: body,
      ),
    );
  }

  void _showLibraryFilter(BuildContext context, List<Category> data) {
    final category = data[DefaultTabController.of(context).index];
    if (context.isTablet) {
      Scaffold.of(context).openEndDrawer();
    } else {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        shape: RoundedRectangleBorder(
          borderRadius: KBorderRadius.rT16.radius,
        ),
        clipBehavior: Clip.hardEdge,
        builder: (_) => LibraryMangaOrganizer(category: category),
      );
    }
  }

  void _reloadListAfterAction(
    BuildContext context,
    WidgetRef ref,
    List<Category> data,
  ) {
    final category = data[DefaultTabController.of(context).index];
    final provider =
        categoryMangaListWithIdProvider(categoryId: category.id ?? 0);
    ref.read(provider.notifier).reloadMangaList();
  }
}
