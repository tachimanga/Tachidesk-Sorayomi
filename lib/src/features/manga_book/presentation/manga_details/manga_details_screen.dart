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
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/classes/trace/trace_ref.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../browse_center/data/source_repository/source_repository.dart';
import '../../../browse_center/presentation/source_manga_list/controller/source_manga_controller.dart';
import '../../../library/presentation/library/controller/library_controller.dart';
import '../../../settings/controller/remote_blacklist_controller.dart';
import '../../../settings/data/config/remote_blacklist_config.dart';
import '../../../settings/presentation/appearance/controller/date_format_controller.dart';
import '../../../settings/presentation/reader/widgets/reader_classic_start_button_tile/reader_classic_start_button_tile.dart';
import '../../../settings/presentation/share/controller/share_controller.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/manga/manga_model.dart';
import '../../widgets/chapter_actions/multi_chapters_actions_bottom_app_bar.dart';
import 'controller/manga_details_controller.dart';
import 'widgets/big_screen_manga_details.dart';
import 'widgets/chapter_filter_icon_button.dart';
import 'widgets/edit_manga_category_dialog.dart';
import 'widgets/manga_chapter_download_button.dart';
import 'widgets/manga_chapter_organizer.dart';
import 'widgets/manga_start_read_fab.dart';
import 'widgets/manga_start_read_icon.dart';
import 'widgets/small_screen_manga_details.dart';

class MangaDetailsScreen extends HookConsumerWidget {
  const MangaDetailsScreen(
      {super.key, required this.mangaId, this.categoryId, this.mangaBasic});
  final String mangaId;
  final int? categoryId;
  final Manga? mangaBasic;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      TraceRef.put(mangaBasic?.sourceId, mangaId);
      return;
    }, []);

    // Providers as Class for this screen
    final mangaProvider =
        useMemoized(() => mangaWithIdProvider(mangaId: mangaId), []);
    final chapterListProvider =
        useMemoized(() => mangaChapterListProvider(mangaId: mangaId), []);
    final chapterListFilteredProvider = useMemoized(
        () => mangaChapterListWithFilterProvider(mangaId: mangaId), []);
    final classicStartButton = ref.watch(readerClassicStartButtonProvider);

    final manga = ref.watch(mangaProvider);

    useEffect(() {
      TraceRef.put(manga.valueOrNull?.sourceId, mangaId);
      return;
    }, [manga]);

    final filteredChapterList = ref.watch(chapterListFilteredProvider);
    final selectedChapters = useState<Map<int, Chapter>>({});

    final blacklistConfig = ref.read(blacklistConfigProvider);
    final blackState = useState(false);
    useEffect(() {
      blackState.value = _checkMangaIsBlack(manga.valueOrNull, blacklistConfig);
      return;
    }, [manga]);

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
    final toast = ref.read(toastProvider(context));
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;

    final animationController =
        useAnimationController(duration: const Duration(seconds: 0));
    useAnimation(animationController);

    final bgColorTween = ColorTween(
      begin: context.theme.appBarTheme.backgroundColor?.withOpacity(0),
      end: context.theme.appBarTheme.backgroundColor?.withOpacity(1),
    ).animate(animationController).value;

    final textColorTween = ColorTween(
      begin: context.theme.appBarTheme.foregroundColor?.withOpacity(0),
      end: context.theme.appBarTheme.foregroundColor?.withOpacity(1),
    ).animate(animationController).value;

    useEffect(() {
      manga.showToastOnError(toast, withMicrotask: true);
      return;
    }, [manga]);

    final localManga = manga.valueOrNull ?? mangaBasic;
    final mangaHasError = !manga.isLoading && manga.hasError;
    final mangaVO = mangaHasError &&
            localManga != null &&
            filteredChapterList.valueOrNull != null
        ? AsyncData(localManga)
        : manga;

    return WillPopScope(
      onWillPop: null,
      child: mangaVO.showUiWhenData(
        context,
        (data) => Scaffold(
          extendBodyBehindAppBar: !context.isTablet,
          appBar: selectedChapters.value.isNotEmpty
              ? AppBar(
                  leading: IconButton(
                    onPressed: () => selectedChapters.value = <int, Chapter>{},
                    icon: const Icon(Icons.close_rounded),
                  ),
                  title: Text(
                    context.l10n!.numSelected(selectedChapters.value.length),
                  ),
                  foregroundColor:
                      context.theme.appBarTheme.foregroundColor?.withOpacity(1),
                  backgroundColor: context.isTablet
                      ? context.theme.appBarTheme.backgroundColor
                          ?.withOpacity(1)
                      : bgColorTween,
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
                  foregroundColor: context.isTablet ? null : textColorTween,
                  backgroundColor: context.isTablet ? null : bgColorTween,
                  actions: [
                    if (context.isTablet) MangaStartReadIcon(mangaId: mangaId),
                    AsyncIconButton(
                      onPressed: data != null
                          ? () async {
                              if (!context.mounted) {
                                return;
                              }
                              final text = context.l10n!.mangaShareText(
                                  data.author ?? "",
                                  data.realUrl ?? "",
                                  data.title ?? "");
                              pipe.invokeMethod(
                                  "LogEvent", "SHARE:SHARE_MANGA");
                              (await AsyncValue.guard(() async {
                                await ref.read(shareActionProvider).shareText(
                                      text,
                                    );
                              }))
                                  .showToastOnError(toast);
                            }
                          : null,
                      icon: const Icon(Icons.share_outlined),
                    ),
                    if (context.isTablet)
                      IconButton(
                        onPressed: () => refresh(true),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    Builder(
                      builder: (context) => ChapterFilterIconButton(
                        mangaId: mangaId,
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
                                builder: (_) => MangaChapterOrganizer(
                                  mangaId: mangaId,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.filter_list_rounded),
                        ),
                      ),
                    ),
                    MangaChapterDownloadButton(mangaId: mangaId),
                    PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: KBorderRadius.r16.radius,
                      ),
                      icon: const Icon(Icons.more_vert_rounded),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (context) =>
                                  EditMangaCategoryDialog(
                                    mangaId: mangaId,
                                    manga: data,
                                  ),
                            );
                            mangaRefresh();
                          },
                          child: Text(context.l10n!.editCategory),
                        ),
                        if (data?.inLibrary == true) ...[
                          PopupMenuItem(
                            onTap: () async {
                              context.push(
                                Routes.getGlobalSearch(data?.title ?? ""),
                                extra: data,
                              );
                            },
                            child: Text(context.l10n!.migrate_action_migrate),
                          ),
                        ],
                        if (!context.isTablet)
                          PopupMenuItem(
                            onTap: () => refresh(true),
                            child: Text(context.l10n!.refresh),
                          ),
                        if (filteredChapterList.valueOrNull?.isNotEmpty == true)
                          PopupMenuItem(
                            onTap: () {
                              final i = filteredChapterList.valueOrNull!.first;
                              selectedChapters.value = {
                                if (i.id != null) i.id!: i
                              };
                            },
                            child: Text(context.l10n!.select_chapters),
                          ),
                        if (data?.sourceId == "0")
                          PopupMenuItem(
                            onTap: () async {
                              (await AsyncValue.guard(() async {
                                await ref
                                    .read(sourceRepositoryProvider)
                                    .removeLocalManga(mangaId: mangaId);
                                final now =
                                    DateTime.now().millisecondsSinceEpoch;
                                ref
                                    .read(localSourceListRefreshSignalProvider
                                        .notifier)
                                    .update(now);
                                if (context.mounted) {
                                  context.pop();
                                }
                              }))
                                  .showToastOnError(toast);
                            },
                            child: Text(context.l10n!.delete),
                          ),
                      ],
                    )
                  ],
                ),
          endDrawer: context.isTablet
              ? Drawer(
                  width: kDrawerWidth,
                  child: MangaChapterOrganizer(
                    mangaId: mangaId,
                  ),
                )
              : null,
          bottomSheet: selectedChapters.value.isNotEmpty
              ? MultiChaptersActionsBottomAppBar(
                  afterOptionSelected: (Map<int, Chapter> prev) async {
                    await chapterListRefresh();
                  },
                  selectedChapters: selectedChapters,
                )
              : null,
          floatingActionButton:
              classicStartButton == true && selectedChapters.value.isEmpty
                  ? MangaStartReadFab(
                      mangaId: mangaId,
                    )
                  : null,
          body: data != null && !blackState.value
              ? context.isTablet
                  ? BigScreenMangaDetails(
                      chapterList: filteredChapterList,
                      manga: data,
                      mangaId: mangaId,
                      onRefresh: refresh,
                      onDescriptionRefresh: mangaRefresh,
                      onListRefresh: chapterListRefresh,
                      selectedChapters: selectedChapters,
                      dateFormatPref: dateFormatPref,
                    )
                  : SmallScreenMangaDetails(
                      chapterList: filteredChapterList,
                      manga: data,
                      mangaId: mangaId,
                      onRefresh: refresh,
                      onDescriptionRefresh: mangaRefresh,
                      onListRefresh: chapterListRefresh,
                      selectedChapters: selectedChapters,
                      dateFormatPref: dateFormatPref,
                      animationController: animationController,
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
        webViewUrlProvider: () async {
          final url = manga.valueOrNull?.realUrl;
          if (url?.isNotEmpty == true) {
            return url;
          }
          return await ref
              .read(mangaBookRepositoryProvider)
              .getMangaRealUrl(mangaId: mangaId);
        },
        wrapper: (body) => Scaffold(
          appBar: AppBar(
            title: Text(mangaBasic?.title ?? context.l10n!.manga),
          ),
          body: mangaBasic == null
              ? body
              : Stack(
                  children: [
                    context.isTablet
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MangaCoverDescriptiveListTile(
                                  manga: mangaBasic!,
                                  showBadges: false,
                                  onTitleClicked: (query) => context
                                      .push(Routes.getGlobalSearch(query)),
                                ),
                              ),
                              const Expanded(child: SizedBox.expand()),
                            ],
                          )
                        : MangaCoverDescriptiveListTile(
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

  bool _checkMangaIsBlack(
    Manga? manga,
    BlacklistConfig blacklistConfig,
  ) {
    if (manga?.realUrl != null
        && blacklistConfig.blackMangaUrlList?.isNotEmpty == true) {
      final url = manga?.realUrl;
      final black = blacklistConfig.blackMangaUrlList?.contains(url) == true;
      if (black) {
        logEvent3("BLACK:MANGA:URL", {"x": url});
        return true;
      }
    }
    return false;
  }
}
