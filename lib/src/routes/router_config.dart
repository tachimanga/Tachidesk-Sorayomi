// Copyright (c) 2022 Contributors to the Suwayomi project
// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/enum.dart';
import '../constants/navigation_bar_data.dart';
import '../features/about/presentation/about/about_screen_lite.dart';
import '../features/about/presentation/about/debug_keyboard_screen.dart';
import '../features/about/presentation/about/debug_screen.dart';
import '../features/browse_center/domain/filter/filter_model.dart';
import '../features/browse_center/domain/migrate/migrate_model.dart';
import '../features/browse_center/presentation/browse/browse_screen.dart';
import '../features/browse_center/presentation/extension/extension_info_screen.dart';
import '../features/browse_center/presentation/global_search/global_search_screen.dart';
import '../features/browse_center/presentation/migrate/migrate_source_detail_screen.dart';
import '../features/browse_center/presentation/source_manga_list/source_manga_list_screen.dart';
import '../features/browse_center/presentation/source_preference/source_preference_screen.dart';
import '../features/browse_center/presentation/webview/webview_screen.dart';
import '../features/custom/inapp/presentation/purchase_screen.dart';
import '../features/library/presentation/category/edit_category_screen.dart';
import '../features/library/presentation/library/library_screen.dart';
import '../features/manga_book/domain/manga/manga_model.dart';
import '../features/manga_book/presentation/downloaded/downloaded_screen.dart';
import '../features/manga_book/presentation/downloads/downloads_screen.dart';
import '../features/manga_book/presentation/history/history_screen.dart';
import '../features/manga_book/presentation/manga_details/manga_details_screen.dart';
import '../features/manga_book/presentation/reader/controller/reader_controller_v2.dart';
import '../features/manga_book/presentation/reader/reader_screen.dart';
import '../features/manga_book/presentation/reader/reader_screen_v2.dart';
import '../features/manga_book/presentation/updates/updates_screen.dart';
import '../features/settings/domain/repo/repo_model.dart';
import '../features/settings/presentation/advanced/advanced_screen.dart';
import '../features/settings/presentation/appearance/appearance_screen.dart';
import '../features/settings/presentation/backup2/backup_screen_v2.dart';
import '../features/settings/presentation/browse/browse_settings_screen.dart';
import '../features/settings/presentation/browse/edit_repo_screen.dart';
import '../features/settings/presentation/browse/extension_detail_screen.dart';
import '../features/settings/presentation/downloads/download_setting_screen.dart';
import '../features/settings/presentation/general/general_screen.dart';
import '../features/settings/presentation/general/widgets/default_tab_tile/default_tab_tile.dart';
import '../features/settings/presentation/lab/labs_screen.dart';
import '../features/settings/presentation/library/library_settings_screen.dart';
import '../features/settings/presentation/more/more_screen_lite.dart';
import '../features/settings/presentation/reader/reader_settings_screen.dart';
import '../features/settings/presentation/reader/reader_tap_zones_settings_screen.dart';
import '../features/settings/presentation/reader/widgets/reader_advanced_setting/reader_advanced_screen.dart';
import '../features/settings/presentation/security/security_setting_screen.dart';
import '../features/settings/presentation/settings/settings_screen.dart';
import '../features/settings/presentation/tracking/tracker_settings_screen.dart';
import '../features/settings/presentation/tracking/tracking_manga_search_screen.dart';
import '../firebase/observer.dart';
import '../global_providers/global_providers.dart';
import '../global_providers/preference_providers.dart';
import '../utils/extensions/custom_extensions.dart';
import '../utils/log.dart';
import '../widgets/shell/shell_screen.dart';

part 'router_config.g.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

abstract class Routes {
  static const home = '/';
  static const library = '/library';
  static const librarySettings = 's-library';
  static const updates = '/updates';
  static const browse = '/browse';
  static const downloads = '/downloads';
  static const downloaded = '/downloaded';
  static const history = '/history';
  static const more = '/more';
  static const about = '/about';
  static const appearanceSettings = 's-appearance';
  static const generalSettings = 's-general';
  static const advancedSettings = 's-advanced';
  static const labsSettings = 's-labs';
  static const debugSettings = 's-debug';
  static const backup = 'backup';
  static const settings = '/settings';
  static const browseSettings = 'extensionSetting';
  static const editRepo = 'edit-repo';
  static const repoDetail = 'repo-detail';
  static getRepoDetail(int repoId, String repoName) => '$repoDetail?repoId=$repoId&repoName=$repoName';
  static const readerSettings = 'reader';
  static const readerAdvancedSettings = 'r-advanced';
  static const readerTapZones = 'tapZones';
  static const trackingSettings = 'tracking';
  static const securitySettings = 'security';
  static const downloadSettings = '/downloadSettings';
  static const reader = '/reader/:mangaId/:chapterIndex';
  static getReader(String mangaId, String chapterIndex) =>
      '/reader/$mangaId/$chapterIndex';
  static const serverSettings = 'server';
  static const editCategories = 'edit-categories';
  static const extensions = '/extensions';
  static const extensionInfo = '/extension/:extensionId';
  static getExtensionInfo(int extensionId) => '/extension/$extensionId';
  static const manga = '/manga/:mangaId';
  static getManga(int mangaId, {int? categoryId}) =>
      '/manga/$mangaId${categoryId.isNull ? '' : "?categoryId=$categoryId"}';
  static const mangaTrackSearch = '/track/search/:trackerId/:mangaId';
  static const mangaTrackSetting = '/track/setting';
  static const mangaCategorySetting = '/category/setting';
  static getMangaTrackSearch(int trackerId, int mangaId) => '/track/search/$trackerId/$mangaId';
  static const sourceManga = '/source/:sourceId/:sourceType';
  static getSourceManga(String sourceId, SourceType sourceType,
          {String? query}) =>
      '/source/$sourceId/${sourceType.name}${query.isNotBlank ? "?query=$query" : ''}';
  static const sourcePref = '/configure/:sourceId';
  static getSourcePref(String sourceId) =>
      '/configure/$sourceId';
  static const globalSearch = '/global-search';
  static getGlobalSearch([String? query]) =>
      '/global-search${query.isNotBlank ? "?query=$query" : ''}';
  static const goWebView = '/webView';
  static getWebView(String url) => '$goWebView?url=$url';
  static const purchase = '/purchase';
  static const migrateMangaList = '/migrate/:sourceId';
  static getMigrateMangaList(String sourceId) => '/migrate/$sourceId';
}

RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

@riverpod
GoRouter routerConfig(ref) {
  final pipe = ref.watch(getMagicPipeProvider);
  final defaultTab = ref.read(defaultTabPrefProvider) ?? DefaultTabEnum.auto;
  final initLocationConfig = defaultTab == DefaultTabEnum.auto
      ? ref.read(initLocationProvider)
      : defaultTab.route;

  final initLocation = NavigationBarData.navList
      .map((e) => e.path)
      .where((path) => initLocationConfig == path)
      .firstOrNull;
  log("[initLocation]defaultTab:$defaultTab, config: $initLocationConfig match: $initLocation");

  final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(channel: pipe);
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: initLocation ?? Routes.browse,
    navigatorKey: _rootNavigatorKey,
    observers: [observer, routeObserver],
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            redirect: (context, state) => Routes.library,
          ),
          GoRoute(
            path: Routes.library,
            pageBuilder: (context, state) => const NoTransitionPage(child: LibraryScreen()),
          ),
          GoRoute(
            path: Routes.updates,
            pageBuilder: (context, state) => const NoTransitionPage(child: UpdatesScreen()),
          ),
          GoRoute(
            path: Routes.browse,
            pageBuilder: (context, state) => const NoTransitionPage(child: BrowseScreen()),
          ),
          GoRoute(
            path: Routes.history,
            pageBuilder: (context, state) => const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: Routes.more,
            // builder: (context, state) => const MoreScreen(),
            pageBuilder: (context, state) => const NoTransitionPage(child: MoreScreenLite()),
          ),
        ],
      ),
      GoRoute(
        path: Routes.manga,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MangaDetailsScreen(
          key: ValueKey(state.params['mangaId'] ?? "2"),
          mangaId: state.params['mangaId'] ?? "",
          categoryId: int.tryParse(state.queryParams['categoryId'] ?? ''),
          mangaBasic: state.extra as Manga?,
        ),
      ),
      GoRoute(
        path: Routes.globalSearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GlobalSearchScreen(
          key: ValueKey(state.queryParams['query'] ?? "1"),
          initialQuery: state.queryParams['query'],
          migrateSrcManga: state.extra as Manga?,
        ),
      ),
      GoRoute(
        path: Routes.sourceManga,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SourceMangaListScreen(
          key: ValueKey(state.params['sourceId'] ?? "0"),
          sourceId: state.params['sourceId'] ?? "0",
          initialQuery: state.queryParams['query'],
          sourceType: SourceType.values.firstWhere(
            (element) => element.name.query(state.params['sourceType']),
            orElse: () => SourceType.popular,
          ),
        ),
      ),
      GoRoute(
        path: Routes.sourcePref,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SourcePreferenceScreen(
          key: ValueKey(state.params['sourceId'] ?? "0"),
          sourceId: state.params['sourceId'] ?? "",
        ),
      ),
      GoRoute(
        path: Routes.extensionInfo,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ExtensionInfoScreen(
          key: ValueKey(state.params['extensionId'] ?? "0"),
          extensionId: int.parse(state.params['extensionId'] ?? ""),
        ),
      ),
      GoRoute(
        path: Routes.about,
        parentNavigatorKey: _rootNavigatorKey,
        // builder: (context, state) => const AboutScreen(),
        builder: (context, state) => const AboutScreenLite(),
      ),
      GoRoute(
        path: Routes.reader,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          if (ref.read(useReader2Provider) == true) {
            return ReaderScreen2(
              mangaId: state.params['mangaId'] ?? '',
              initChapterIndex: state.params['chapterIndex'] ?? '',
            );
          }
          return ReaderScreen(
            mangaId: state.params['mangaId'] ?? '',
            chapterIndex: state.params['chapterIndex'] ?? '',
          );
        },
      ),
      GoRoute(
        path: Routes.mangaTrackSearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TrackingMangaSearchScreen(
          key: ValueKey(state.params['trackerId'] ?? ""),
          trackerId: int.parse(state.params['trackerId'] ?? ""),
          mangaId: int.parse(state.params['mangaId'] ?? ""),
        ),
      ),
      GoRoute(
        path: Routes.mangaTrackSetting,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TrackerSettingsScreen(),
      ),
      GoRoute(
        path: Routes.mangaCategorySetting,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditCategoryScreen(),
      ),
      GoRoute(
        path: Routes.migrateMangaList,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MigrateSourceDetailScreen(
          key: ValueKey(state.params['sourceId'] ?? "0"),
          sourceId: state.params['sourceId'] ?? "0",
          migrateSource: state.extra as MigrateSource?,
        ),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: Routes.librarySettings,
            builder: (context, state) => const LibrarySettingsScreen(),
            routes: [
              GoRoute(
                path: Routes.editCategories,
                builder: (context, state) => const EditCategoryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.readerSettings,
            builder: (context, state) => const ReaderSettingsScreen(),
            routes: [
              GoRoute(
                path: Routes.readerTapZones,
                builder: (context, state) => const ReaderTapZonesSettingsScreen(),
              ),
              GoRoute(
                path: Routes.readerAdvancedSettings,
                builder: (context, state) => const ReaderAdvancedScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.trackingSettings,
            builder: (context, state) => const TrackerSettingsScreen(),
          ),
          GoRoute(
            path: Routes.appearanceSettings,
            builder: (context, state) => const AppearanceScreen(),
          ),
          GoRoute(
            path: Routes.generalSettings,
            builder: (context, state) => const GeneralScreen(),
            routes: [
              GoRoute(
                path: Routes.advancedSettings,
                builder: (context, state) => const AdvancedScreen(),
              ),
              GoRoute(
                path: Routes.labsSettings,
                builder: (context, state) => const LabsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: Routes.debugSettings,
            builder: (context, state) => const DebugScreen(),
          ),
          GoRoute(
            path: 's-keyboard',
            builder: (context, state) => const DebugKeyboardScreen(),
          ),
          GoRoute(
            path: Routes.browseSettings,
            builder: (context, state) => const BrowseSettingsScreen(),
            routes: [
              GoRoute(
                path: Routes.editRepo,
                builder: (context, state) => EditRepoScreen(
                  urlSchemeAddRepo: state.extra as UrlSchemeAddRepo?,
                ),
                routes: [
                  GoRoute(
                    path: Routes.repoDetail,
                    builder: (context, state) => ExtensionDetailScreen(
                      repoId: int.parse(state.queryParams['repoId'] ?? ""),
                      repoName: state.queryParams['repoName'] ?? "",
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Routes.backup,
            builder: (context, state) => BackupScreenV2(
              importBackupFilePath: state.extra as String?,
            ),
          ),
          GoRoute(
            path: Routes.securitySettings,
            builder: (context, state) => const SecuritySettingScreen(),
          ),
        ],
      ),
      GoRoute(
        path: Routes.downloads,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: Routes.downloaded,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadedScreen(),
      ),
      GoRoute(
        path: Routes.downloadSettings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadSettingScreen(),
      ),
      GoRoute(
        path: Routes.goWebView,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WebViewScreen(
          url: state.queryParams['url'],
        ),
      ),
      GoRoute(
        path: Routes.purchase,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PurchaseScreen(),
      ),
    ],
  );
}
