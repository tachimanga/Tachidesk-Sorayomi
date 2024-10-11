// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/db_keys.dart';
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/classes/trace/trace_ref.dart';
import '../../../../utils/cover/cover_cache_manager.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/image_util.dart';
import '../../../../utils/log.dart';
import '../../../../utils/manga_cover_util.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../library/presentation/library/controller/library_controller.dart';
import '../../../settings/controller/remote_blacklist_controller.dart';
import '../../../settings/data/config/remote_blacklist_config.dart';
import '../../../settings/presentation/appearance/controller/date_format_controller.dart';
import '../../../settings/presentation/reader/widgets/reader_classic_start_button_tile/reader_classic_start_button_tile.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/manga/manga_model.dart';
import '../../widgets/chapter_actions/multi_chapters_actions_bottom_app_bar.dart';
import '../reader/controller/reader_controller_v2.dart';
import 'controller/manga_details_controller.dart';
import 'manga_details_app_bar.dart';
import 'widgets/big_screen_manga_details.dart';
import 'widgets/manga_chapter_organizer.dart';
import 'widgets/manga_start_read_fab.dart';
import 'widgets/small_screen_manga_details.dart';

Set<String> autoRefreshMangaIdSet = {};

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

    final coverRefreshState = useState(false);

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
      final freshManga = await mangaRefresh(onlineFetch);
      if (context.mounted && onlineFetch && freshManga != null) {
        _refreshMangaCover(
            context, ref, mangaId, freshManga, coverRefreshState);
      }
      if (context.mounted) {
        await chapterListRefresh(onlineFetch);
      }
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

    final refreshIndicatorKey = useRef(GlobalKey<RefreshIndicatorState>());
    useEffect(() {
      autoRefreshIfNeeded(
        context,
        ref,
        manga.valueOrNull,
        mangaId,
        autoRefreshMangaIdSet,
        refreshIndicatorKey,
      );
      return;
    }, [manga]);

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
          appBar: MangaDetailsAppBar(
            mangaId: mangaId,
            data: data,
            filteredChapterList: filteredChapterList,
            selectedChapters: selectedChapters,
            animationController: animationController,
            refresh: refresh,
            mangaRefresh: mangaRefresh,
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
                  showDownload: data?.sourceId != "0",
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
                      showCoverRefreshIndicator: coverRefreshState.value,
                      refreshIndicatorKey: refreshIndicatorKey,
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
                      showCoverRefreshIndicator: coverRefreshState.value,
                      refreshIndicatorKey: refreshIndicatorKey,
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

  void autoRefreshIfNeeded(
      BuildContext context,
      WidgetRef ref,
      Manga? manga,
      String mangaId,
      Set<String> autoRefreshMangaIdSet,
      ObjectRef<GlobalKey<RefreshIndicatorState>> refreshIndicatorKey) {
    if (ref.read(autoRefreshMangaProvider) != true) {
      return;
    }
    if (autoRefreshMangaIdSet.contains(mangaId)) {
      return;
    }
    if (manga == null) {
      return;
    }
    if (manga.sourceId == "0") {
      return;
    }
    if (manga.freshData != false) {
      return;
    }
    if (manga.updateStrategy != "ALWAYS_UPDATE") {
      return;
    }
    if (manga.status == MangaStatus.completed) {
      return;
    }
    if (manga.chaptersLastFetchedAt == null) {
      return;
    }
    final diff =
        DateTime.now().secondsSinceEpoch - manga.chaptersLastFetchedAt!;
    if (diff > 86400) {
      Future(() async {
        final connectivity = await Connectivity().checkConnectivity();
        if (connectivity == ConnectivityResult.none) {
          return;
        }
        if (context.mounted) {
          autoRefreshMangaIdSet.add(mangaId);
          refreshIndicatorKey.value.currentState?.show();
        }
      });
    }
  }

  bool _checkMangaIsBlack(
    Manga? manga,
    BlacklistConfig blacklistConfig,
  ) {
    if (manga?.realUrl != null &&
        blacklistConfig.blackMangaUrlList?.isNotEmpty == true) {
      final url = manga?.realUrl;
      final black = blacklistConfig.blackMangaUrlList?.contains(url) == true;
      if (black) {
        logEvent3("BLACK:MANGA:URL", {"x": url});
        return true;
      }
    }
    return false;
  }

  void _refreshMangaCover(
    BuildContext context,
    WidgetRef ref,
    String mangaId,
    Manga manga,
    ValueNotifier<bool> coverRefreshState,
  ) async {
    //log("[CacheManager] _refreshMangaCover...");
    try {
      final shouldRefresh =
          await CoverCacheManager().shouldRefreshCover(mangaId);
      if (!shouldRefresh) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      _updateCoverRefreshState(context, coverRefreshState, true);
      final url = buildImageUrl(
          imageUrl: manga.thumbnailUrl ?? "",
          imageData: manga.thumbnailImg,
          baseUrl: DBKeys.serverUrl.initial);
      await CoverCacheManager().refreshCover(
        url,
        headers: manga.thumbnailImg?.headers,
        extInfo: CoverExtInfo.build(manga),
      );
      if (!context.mounted) {
        return;
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ref.read(mangaWithIdProvider(mangaId: "${manga.id}").notifier).refresh();
      //log("[CacheManager] _refreshMangaCover. done");
    } catch (e) {
      log("[CacheManager] _refreshMangaCover err=$e");
    }
    _updateCoverRefreshState(context, coverRefreshState, false);
  }

  void _updateCoverRefreshState(
    BuildContext context,
    ValueNotifier<bool> state,
    bool value,
  ) {
    try {
      if (context.mounted) {
        state.value = value;
      }
    } catch (e) {
      log("[CacheManager] _updateCoverRefreshState err=$e");
    }
  }
}
