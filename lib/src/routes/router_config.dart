// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/enum.dart';
import '../features/about/presentation/about/about_screen.dart';
import '../features/about/presentation/about/about_screen_lite.dart';
import '../features/browse_center/domain/filter/filter_model.dart';
import '../features/browse_center/presentation/browse/browse_screen.dart';
import '../features/browse_center/presentation/global_search/global_search_screen.dart';
import '../features/browse_center/presentation/source_manga_list/source_manga_list_screen.dart';
import '../features/browse_center/presentation/source_preference/source_pref_screen.dart';
import '../features/browse_center/presentation/webview/webview_screen.dart';
import '../features/custom/inapp/presentation/purchase_screen.dart';
import '../features/library/presentation/category/edit_category_screen.dart';
import '../features/library/presentation/library/library_screen.dart';
import '../features/manga_book/presentation/downloads/downloads_screen.dart';
import '../features/manga_book/presentation/history/history_screen.dart';
import '../features/manga_book/presentation/manga_details/manga_details_screen.dart';
import '../features/manga_book/presentation/reader/reader_screen.dart';
import '../features/manga_book/presentation/updates/updates_screen.dart';
import '../features/settings/presentation/appearance/appearance_screen.dart';
import '../features/settings/presentation/backup/backup_screen.dart';
import '../features/settings/presentation/browse/browse_settings_screen.dart';
import '../features/settings/presentation/general/general_screen.dart';
import '../features/settings/presentation/library/library_settings_screen.dart';
import '../features/settings/presentation/more/more_screen.dart';
import '../features/settings/presentation/more/more_screen_lite.dart';
import '../features/settings/presentation/reader/reader_settings_screen.dart';
import '../features/settings/presentation/server/server_screen.dart';
import '../features/settings/presentation/settings/settings_screen.dart';
import '../global_providers/global_providers.dart';
import '../utils/extensions/custom_extensions.dart';
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
  static const downloads = 'downloads';
  static const history = '/history';
  static const more = '/more';
  static const about = '/about';
  static const appearanceSettings = 's-appearance';
  static const generalSettings = 's-general';
  static const backup = 'backup';
  static const settings = '/settings';
  static const browseSettings = 'extensionSetting';
  static getExtensionSetting(String name, String url) =>
    '$browseSettings?name=$name&url=$url';
  static const readerSettings = 'reader';
  static const reader = '/reader/:mangaId/:chapterIndex';
  static getReader(String mangaId, String chapterIndex) =>
      '/reader/$mangaId/$chapterIndex';
  static const serverSettings = 'server';
  static const editCategories = 'edit-categories';
  static const extensions = '/extensions';
  static const manga = '/manga/:mangaId';
  static getManga(int mangaId, {int? categoryId}) =>
      '/manga/$mangaId${categoryId.isNull ? '' : "?categoryId=$categoryId"}';
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
}

@riverpod
GoRouter routerConfig(ref) {
  var pipe = ref.watch(getMagicPipeProvider);
  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: Routes.browse,
    navigatorKey: _rootNavigatorKey,
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
        ),
      ),
      GoRoute(
        path: Routes.globalSearch,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => GlobalSearchScreen(
          key: ValueKey(state.queryParams['query'] ?? "1"),
          initialQuery: state.queryParams['query'],
        ),
      ),
      GoRoute(
        path: Routes.sourceManga,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SourceMangaListScreen(
          key: ValueKey(state.params['sourceId'] ?? "0"),
          sourceId: state.params['sourceId'] ?? "0",
          initialQuery: state.queryParams['query'],
          initialFilter: (state.extra is List<Filter>?)
              ? (state.extra as List<Filter>?)
              : null,
          sourceType: SourceType.values.firstWhere(
            (element) => element.name.query(state.params['sourceType']),
            orElse: () => SourceType.popular,
          ),
        ),
      ),
      GoRoute(
        path: Routes.sourcePref,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SourcePrefScreen(
          key: ValueKey(state.params['sourceId'] ?? "0"),
          sourceId: state.params['sourceId'] ?? "",
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
        builder: (context, state) => ReaderScreen(
          mangaId: state.params['mangaId'] ?? '',
          chapterIndex: state.params['chapterIndex'] ?? '',
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
            path: Routes.serverSettings,
            builder: (context, state) => const ServerScreen(),
          ),
          GoRoute(
            path: Routes.readerSettings,
            builder: (context, state) => const ReaderSettingsScreen(),
          ),
          GoRoute(
            path: Routes.appearanceSettings,
            builder: (context, state) => const AppearanceScreen(),
          ),
          GoRoute(
            path: Routes.generalSettings,
            builder: (context, state) => const GeneralScreen(),
          ),
          GoRoute(
            path: Routes.browseSettings,
            builder: (context, state) => BrowseSettingsScreen(
              repoName: state.queryParams['name'],
              repoUrl: state.queryParams['url'],
            ),
          ),
          GoRoute(
            path: Routes.backup,
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: Routes.downloads,
            builder: (context, state) => const DownloadsScreen(),
          ),
        ],
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
