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
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../library/presentation/library/controller/library_controller.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/manga/manga_model.dart';
import '../../widgets/chapter_actions/multi_chapters_actions_bottom_app_bar.dart';
import 'controller/manga_details_controller.dart';
import 'widgets/big_screen_manga_details.dart';
import 'widgets/edit_manga_category_dialog.dart';
import 'widgets/manga_chapter_organizer.dart';
import 'widgets/small_screen_manga_details.dart';

class MangaDetailsScreen extends HookConsumerWidget {
  const MangaDetailsScreen(
      {super.key, required this.mangaId, this.categoryId, this.mangaBasic});
  final String mangaId;
  final int? categoryId;
  final Manga? mangaBasic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Providers as Class for this screen
    final mangaProvider =
        useMemoized(() => mangaWithIdProvider(mangaId: mangaId), []);
    final chapterListProvider =
        useMemoized(() => mangaChapterListProvider(mangaId: mangaId), []);
    final chapterListFilteredProvider = useMemoized(
        () => mangaChapterListWithFilterProvider(mangaId: mangaId), []);

    final manga = ref.watch(mangaProvider);
    final filteredChapterList = ref.watch(chapterListFilteredProvider);
    final firstUnreadChapter = ref.watch(
      firstUnreadInFilteredChapterListProvider(mangaId: mangaId),
    );

    final selectedChapters = useState<Map<int, Chapter>>({});

    // Refresh manga
    final mangaRefresh = useCallback(
        ([bool onlineFetch = false]) async =>
            await ref.read(mangaProvider.notifier).refresh(onlineFetch),
        [mangaProvider]);

    // Refresh chapter list
    final chapterListRefresh = useCallback(
        ([bool onlineFetch = false]) async =>
            await ref.read(chapterListProvider.notifier).refresh(onlineFetch),
        [chapterListProvider]);
    final refresh = useCallback(([onlineFetch = false]) async {
      if (context.mounted && onlineFetch) {
        ref.read(toastProvider(context)).show(
              context.l10n!.updating,
              withMicrotask: true,
            );
      }
      await mangaRefresh(onlineFetch);
      await chapterListRefresh(onlineFetch);
      if (context.mounted && onlineFetch) {
        ref.read(toastProvider(context)).show(
              context.l10n!.updateCompleted,
              withMicrotask: true,
            );
      }
    }, []);

    useEffect(() {
      if (!filteredChapterList.isLoading && !manga.isLoading) refresh();
      return;
    }, []);
/*
    useEffect(() {
      if (filteredChapterList.hasValue
          && filteredChapterList.value?.isNotEmpty == true) {
        final chapter = filteredChapterList.value![0];
        if (chapter.fromCache == true) {
          Future.microtask(() => refresh(true));
        }
      }
      return;
    }, [filteredChapterList]);
*/
    useRouteObserver(routeObserver, didPop: () {
      log("MangaDetailsScreen did pop");
      if (categoryId != null) {
        ref.invalidate(categoryMangaListProvider(categoryId!));
      }
    });
    return WillPopScope(
      onWillPop: null,
      child: manga.showUiWhenData(
        context,
        (data) => Scaffold(
          appBar: selectedChapters.value.isNotEmpty
              ? AppBar(
                  leading: IconButton(
                    onPressed: () => selectedChapters.value = <int, Chapter>{},
                    icon: const Icon(Icons.close_rounded),
                  ),
                  title: Text(
                    context.l10n!.numSelected(selectedChapters.value.length),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        selectedChapters.value = {
                          for (Chapter i in [
                            ...?filteredChapterList.valueOrNull
                          ])
                            if (i.id != null) i.id!: i
                        };
                      },
                      icon: const Icon(Icons.select_all_rounded),
                    ),
                    IconButton(
                      onPressed: () {
                        selectedChapters.value = {
                          for (Chapter i in [
                            ...?filteredChapterList.valueOrNull
                          ])
                            if (i.id != null &&
                                !selectedChapters.value.containsKey(i.id))
                              i.id!: i
                        };
                      },
                      icon: const Icon(Icons.flip_to_back_rounded),
                    ),
                  ],
                )
              : AppBar(
                  title: Text(data?.title ?? context.l10n!.manga),
                  actions: [
                    if (context.isTablet)
                      IconButton(
                        onPressed: () => refresh(true),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    Builder(
                      builder: (context) => IconButton(
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
                              builder: (_) => const MangaChapterOrganizer(),
                            );
                          }
                        },
                        icon: const Icon(Icons.filter_list_rounded),
                      ),
                    ),
                    PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: KBorderRadius.r16.radius,
                      ),
                      icon: const Icon(Icons.more_vert_rounded),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => Future.microtask(
                            () => showDialog(
                              context: context,
                              builder: (context) =>
                                  EditMangaCategoryDialog(mangaId: mangaId),
                            ),
                          ),
                          child: Text(context.l10n!.editCategory),
                        ),
                        if (!context.isTablet)
                          PopupMenuItem(
                            onTap: () => refresh(true),
                            child: Text(context.l10n!.refresh),
                          ),
                      ],
                    )
                  ],
                ),
          endDrawer: const Drawer(
            width: kDrawerWidth,
            child: MangaChapterOrganizer(),
          ),
          bottomSheet: selectedChapters.value.isNotEmpty
              ? MultiChaptersActionsBottomAppBar(
                  afterOptionSelected: chapterListRefresh,
                  selectedChapters: selectedChapters,
                )
              : null,
          floatingActionButton: firstUnreadChapter != null
              && selectedChapters.value.isEmpty
              ? FloatingActionButton.extended(
                  label: Text(
                    data?.lastChapterRead?.index != null
                        ? context.l10n!.resume
                        : context.l10n!.start,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () {
                    context.push(
                      Routes.getReader(
                        "${firstUnreadChapter.mangaId ?? mangaId}",
                        "${firstUnreadChapter.index ?? 0}",
                      ),
                    );
                  },
                )
              : null,
          body: data != null
              ? context.isTablet
                  ? BigScreenMangaDetails(
                      chapterList: filteredChapterList,
                      manga: data,
                      mangaId: mangaId,
                      onRefresh: refresh,
                      onDescriptionRefresh: mangaRefresh,
                      onListRefresh: chapterListRefresh,
                      selectedChapters: selectedChapters,
                    )
                  : SmallScreenMangaDetails(
                      chapterList: filteredChapterList,
                      manga: data,
                      mangaId: mangaId,
                      onRefresh: refresh,
                      onDescriptionRefresh: mangaRefresh,
                      onListRefresh: chapterListRefresh,
                      selectedChapters: selectedChapters,
                    )
              : Emoticons(
                  text: context.l10n!.noMangaFound,
                  button: TextButton(
                    onPressed: refresh,
                    child: Text(context.l10n!.refresh),
                  ),
                ),
        ),
        refresh: refresh,
        errorSource: "manga-details",
        webViewUrl: manga.valueOrNull?.realUrl,
        wrapper: (body) => Scaffold(
          appBar: AppBar(
            title: Text(mangaBasic?.title ?? context.l10n!.manga),
          ),
          body: context.isTablet || mangaBasic == null
              ? body
              : Stack(
            children: [
              MangaCoverDescriptiveListTile(
                manga: mangaBasic!,
                showBadges: false,
                onTitleClicked: (query) =>
                    context.push(Routes.getGlobalSearch(query)),
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}
