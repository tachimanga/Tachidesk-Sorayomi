// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/db_keys.dart';
import '../../../../constants/enum.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/hooks/paging_controller_hook.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/emoticons.dart';
import '../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../settings/presentation/appearance/controller/date_format_controller.dart';
import '../../data/manga_book_repository.dart';
import '../../data/updates/updates_repository.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/chapter_page/chapter_page_model.dart';
import '../../widgets/chapter_actions/multi_chapters_actions_bottom_app_bar.dart';
import '../../widgets/update_status_fab.dart';
import '../../widgets/update_status_popup_menu.dart';
import 'controller/update_controller.dart';
import 'widgets/chapter_manga_list_tile.dart';
import 'widgets/update_status_list_tile.dart';
import 'widgets/updates_pip_button.dart';

class UpdatesScreen extends HookConsumerWidget {
  const UpdatesScreen({super.key});

  Future<void> _fetchPage(
    UpdatesRepository repository,
    PagingController<int, ChapterMangaPair> controller,
    int pageKey,
  ) async {
    AsyncValue.guard(
      () async => await repository.getRecentChaptersPage(pageNo: pageKey),
    ).then(
      (value) => value.whenOrNull(
        data: (recentChaptersPage) {
          try {
            if (recentChaptersPage != null) {
              if (recentChaptersPage.hasNextPage.ifNull()) {
                controller
                    .appendPage([...?recentChaptersPage.page], pageKey + 1);
              } else {
                controller.appendLastPage([...?recentChaptersPage.page]);
              }
            }
          } catch (e) {
            //
          }
        },
        error: (error, stackTrace) => controller.error = error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        usePagingController<int, ChapterMangaPair>(firstPageKey: 0);
    final updatesRepository = ref.watch(updatesRepositoryProvider);
    final mangaBookRepository = ref.watch(mangaBookRepositoryProvider);
    useEffect(() {
      controller.addPageRequestListener((pageKey) => _fetchPage(
            updatesRepository,
            controller,
            pageKey,
          ));
      return;
    }, []);
    final selectedChapters = useState<Map<int, Chapter>>({});
    final alwaysAskSelect = ref.watch(alwaysAskCategoryToUpdatePrefProvider) ??
        DBKeys.alwaysAskCategoryToUpdate.initial;
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;

    final showPipButton = ref.watch(updateShowPipButtonProvider);

    final refreshSignal = ref.watch(updateRefreshSignalProvider);
    useEffect(() {
      if (refreshSignal) {
        controller.refresh();
      }
      return;
    }, [refreshSignal]);

    final updateRunning = ref.watch(updateRunningProvider);
    final categoryListValue = ref.watch(categoryControllerProvider);
    final showUpdateStatus = ref.watch(showUpdateStatusProvider);

    return Scaffold(
      appBar: selectedChapters.value.isNotEmpty
          ? AppBar(
              leading: IconButton(
                onPressed: () => selectedChapters.value = <int, Chapter>{},
                icon: const Icon(Icons.close_rounded),
              ),
              title: Text(
                context.l10n!.numSelected(selectedChapters.value.length),
              ),
            )
          : AppBar(
              title: Text(context.l10n!.updates),
              centerTitle: true,
              bottom: showUpdateStatus
                  ? PreferredSize(
                      preferredSize: kCalculateAppBarBottomSizeV2(
                        showUpdateStatus: showUpdateStatus,
                      ),
                      child: const UpdateStatusListTile(),
                    )
                  : null,
              actions: [
                if (!alwaysAskSelect) const UpdateSettingIcon(),
                if (showPipButton) const UpdatesPipButton(),
                const UpdateStatusPopupMenu()
              ],
            ),
      bottomSheet: selectedChapters.value.isNotEmpty
          ? MultiChaptersActionsBottomAppBar(
              selectedChapters: selectedChapters,
              afterOptionSelected: (Map<int, Chapter> prev) async {
                final chapterIds = [...prev.keys];
                await _refreshChaptersData(
                  chapterIds,
                  mangaBookRepository,
                  controller,
                );
              },
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          selectedChapters.value = <int, Chapter>{};
          controller.refresh();
          if (!updateRunning && !showUpdateStatus) {
            categoryListValue.whenOrNull(data: (categoryList) {
              fetchUpdates(context, ref, categoryList);
              return;
            });
          }
        },
        child: PagedListView(
          pagingController: controller,
          builderDelegate: PagedChildBuilderDelegate<ChapterMangaPair>(
            firstPageErrorIndicatorBuilder: (context) => Emoticons(
              text: controller.error.toString(),
              button: TextButton(
                onPressed: () => controller.refresh(),
                child: Text(context.l10n!.retry),
              ),
            ),
            noItemsFoundIndicatorBuilder: (context) => updateRunning
                ? const CenterCircularProgressIndicator()
                : Emoticons(
                    text: context.l10n!.noUpdatesFound,
                    button: TextButton(
                      onPressed: () {
                        controller.refresh();
                        if (!updateRunning && !showUpdateStatus) {
                          categoryListValue.whenOrNull(data: (categoryList) {
                            fetchUpdates(context, ref, categoryList);
                            return;
                          });
                        }
                      },
                      child: Text(context.l10n!.refresh),
                    ),
                  ),
            itemBuilder: (context, item, index) {
              int? previousDate;
              try {
                previousDate =
                    controller.itemList?[index - 1].chapter?.fetchedAt;
              } catch (e) {
                previousDate = null;
              }
              final chapterTile = ChapterMangaListTile(
                pair: item,
                updatePair: () async {
                  if (item.chapter?.id != null) {
                    final chapterIds = [item.chapter!.id!];
                    await _refreshChaptersData(
                      chapterIds,
                      mangaBookRepository,
                      controller,
                    );
                  }
                },
                isSelected:
                    selectedChapters.value.containsKey(item.chapter!.id!),
                canTapSelect: selectedChapters.value.isNotEmpty,
                toggleSelect: (Chapter val) {
                  if ((val.id).isNull) return;
                  selectedChapters.value =
                      selectedChapters.value.toggleKey(val.id!, val);
                },
              );
              if ((item.chapter?.fetchedAt).isSameDayAs(previousDate)) {
                return chapterTile;
              } else {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        item.chapter!.fetchedAt.toLocalizedDaysAgoFromSeconds(
                          dateFormatPref,
                          context,
                        ),
                      ),
                    ),
                    chapterTile,
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshChaptersData(
    List<int> chapterIds,
    MangaBookRepository mangaBookRepository,
    PagingController<int, ChapterMangaPair> controller,
  ) async {
    final chapterList =
        await mangaBookRepository.batchQueryChapter(chapterIds: chapterIds);
    final chaptersMap = <int?, Chapter>{};
    chapterList?.forEach((item) {
      chaptersMap[item.id] = item;
    });

    final itemList = controller.itemList?.map((e) {
      final chapterId = e.chapter?.id;
      if (chapterId != null) {
        final chapter = chaptersMap[chapterId];
        if (chapter != null) {
          return e.copyWith(chapter: chapter);
        }
      }
      return e;
    }).toList();
    controller.itemList = itemList;
  }
}
