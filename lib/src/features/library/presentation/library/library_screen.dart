// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../../browse_center/presentation/migrate/controller/migrate_controller.dart';
import '../../../manga_book/presentation/updates/controller/update_controller.dart';
import '../../../manga_book/presentation/updates/widgets/update_status_list_tile.dart';
import '../../../manga_book/widgets/update_status_fab.dart';
import '../../../manga_book/widgets/update_status_popup_menu.dart';
import '../category/controller/edit_category_controller.dart';
import 'category_manga_list.dart';
import 'controller/library_controller.dart';
import 'widgets/library_category_tab.dart';
import 'widgets/library_filter_icon_button.dart';
import 'widgets/library_manga_organizer.dart';

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
                  title: Text(context.l10n!.library),
                  centerTitle: true,
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
                  actions: [
                    IconButton(
                      onPressed: () => showSearch.value = true,
                      icon: const Icon(Icons.search_rounded),
                    ),
                    Builder(
                      builder: (context) => LibraryFilterIconButton(
                          icon: IconButton(
                        onPressed: () {
                          if (context.isTablet) {
                            Scaffold.of(context).openEndDrawer();
                          } else {
                            showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: KBorderRadius.rT16.radius,
                              ),
                              clipBehavior: Clip.hardEdge,
                              builder: (_) => const LibraryMangaOrganizer(),
                            );
                          }
                        },
                        icon: const Icon(Icons.filter_list_rounded),
                      )),
                    ),
                    Builder(
                      builder: (context) {
                        return UpdateStatusPopupMenu(
                          getCategory: () => data.isNotBlank
                              ? data[DefaultTabController.of(context).index]
                              : null,
                        );
                      },
                    ),
                  ],
                ),
                endDrawerEnableOpenDragGesture: false,
                endDrawer: context.isTablet
                    ? const Drawer(
                        width: kDrawerWidth,
                        child: LibraryMangaOrganizer(),
                      )
                    : null,
                body: Padding(
                  padding: KEdgeInsets.h8.size,
                  child: TabBarView(
                    children: data
                        .map((e) => CategoryMangaList(
                              categoryId: e.id ?? 0,
                              categoryCount: data.length,
                            ))
                        .toList(),
                  ),
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
}
