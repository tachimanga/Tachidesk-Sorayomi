// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'db_keys.dart';

abstract class Endpoints {
  // base url
  static String baseApi({String? baseUrl, bool appendApiToUrl = true}) =>
      "${baseUrl ?? DBKeys.serverUrl.initial}"
      "${appendApiToUrl ? '/api/v1' : ''}";

  // receiveTimeout
  static const Duration receiveTimeout = Duration(seconds: 20);

  // connectTimeout
  static const Duration connectionTimeout = Duration(seconds: 20);

  // api3
  static const String api3host = "https://api3.tachimanga.app";
}

abstract class SettingsUrl {
  static const String about = '$_settings/about';
  static const String uploadSettings = '$_settings/uploadSettings';
  static const String clearCookies = '$_settings/clearCookies';
  static const String _settings = "/settings";
}

abstract class GlobalMetaUrl {
  static const String query = '$_meta/query';
  static const String update = '$_meta/update';
  static const String _meta = "/meta";
}

abstract class ExtensionUrl {
  static const String _extension = "/extension";
  static const String list = "$_extension/list";
  static const String installFile = "$_extension/install";
  static String installPkg(int extensionId) => "$installFile/$extensionId";
  static String updatePkg(int extensionId) => "$_extension/update/$extensionId";
  static String uninstallPkg(int extensionId) =>
      "$_extension/uninstall/$extensionId";
  static String icon(String apkName) => "$_extension/icon/$apkName";
}

abstract class CategoryUrl {
  static const String category = "/category";
  static const String reorder = "$category/reorder";
  static String withId(int id) => "$category/$id";
  static String meta(int id) => "$category/$id/meta";
}

abstract class RepoUrl {
  static const String repo = "/repo";
  static const String list = "$repo/list";
  static const String check = "$repo/check";
  static const String create = "$repo/create";
  static const String updateByMetaUrl = "$repo/updateByMetaUrl";
  static String removeWithId(int id) => "$repo/remove/$id";
}

abstract class MangaUrl {
  static String withId(int mangaId) => "$_manga/$mangaId";
  static String fullWithId(String mangaId) => "$_manga/$mangaId/full";
  static String thumbnail(int mangaId) => "$_manga/$mangaId/thumbnail";
  static String category(String mangaId) => "$_manga/$mangaId/category";
  static String updateCategory(String mangaId) => "$_manga/$mangaId/updateCategory";
  static String library(String mangaId) => "$_manga/$mangaId/library";
  static String meta(String mangaId) => "$_manga/$mangaId/meta";
  static String chapters(String mangaId) => "$_manga/$mangaId/chapters";
  static String chapterWithIndex(
    String mangaId,
    String chapterIndex,
  ) =>
      "$_manga/$mangaId/chapter/$chapterIndex";
  static String chapterMetaWithIndex(int mangaId, int chapterIndex) =>
      "$_manga/$mangaId/chapter/$chapterIndex/meta";
  static String chapterBatch = "/chapter/batch";
  static String chapterBatchQuery = "/chapter/batchQuery";
  static String chapterModify = "$_manga/chapter/modify";
  static String chapterPageWithIndex({
    required String mangaId,
    required String chapterIndex,
    required String pageIndex,
  }) =>
      "$_manga/$mangaId/chapter/$chapterIndex/page/$pageIndex";
  static String mangaBatch = "$_manga/batchUpdate";

  static const String _manga = "/manga";
}

abstract class HistoryUrl {
  static const String list = "/history/list";
  static const String batchDelete = "/history/batch";
  static const String clear = "/history/clear";
}

abstract class TrackingUrl {
  static const String list = "/track/list";
  static const String login = "/track/login";
  static const String logout = "/track/logout";
  static const String search = "/track/search";
  static const String bind = "/track/bind";
  static const String update = "/track/update";
}

abstract class DownloaderUrl {
  static String start = "$downloads/start";
  static String stop = "$downloads/stop";
  static String clear = "$downloads/clear";

  static String batch = "/download/batch";
  static String chapter(int mangaId, int chapterIndex) =>
      "/download/$mangaId/chapter/$chapterIndex";

  static String reorderDownload(int mangaId, int chapterIndex, int to) =>
      "/download/$mangaId/chapter/$chapterIndex/reorder/$to";

  static const String downloads = "/downloads";
}

abstract class DownloadedUrl {
  static const String list = "/downloaded/list";
  static const String batchDelete = "/downloaded/batch";
  static const String batchRemoveLegacyDownloads = "/downloaded/batchRemoveLegacyDownloads";
  static const String batchQueryMangaInfo = "/downloaded/batchQueryMangaInfo";
}

abstract class ProtoBackupUrl {
  static String import = "/proto/import";
  static String importWs = "/proto/importWs";
  static String export = "/proto/export";
}

abstract class SourceUrl {
  static String sourceList = "$_source/list";
  static String sourceListForSearch = "$_source/listForSearch";

  static String withId(String sourceId) => "$_source/$sourceId";
  static String getMangaList(String sourceId, String sourceType, int pageNum) =>
      "$_source/$sourceId/$sourceType/$pageNum";
  static String preferences(String sourceId) =>
      "$_source/$sourceId/preferences";
  static String filters(String sourceId) => "$_source/$sourceId/filters";
  static String search(String sourceId) => "$_source/$sourceId/search";
  static String quickSearch(String sourceId) =>
      "$_source/$sourceId/quick-search";
  static const String queryMeta = "$_source/meta/query";
  static const String updateMeta = "$_source/meta/update";

  static const String _source = "/source";
}

abstract class UpdateUrl {
  static String recentChapters(int pageNo) => "$update/recentChapters/$pageNo";

  static const String update = "/update";
  static const String fetch = "/update/fetch2";
  static const String retryByCodes = "/update/retryByCodes";
  static const String retrySkipped = "/update/retrySkipped";
  static const String reset = "/update/reset";
  static const String summary = "/update/summary";
}

abstract class MigrateUrl {
  static const String migrate = "/migrate";
  static const String info = "$migrate/info";
  static const String sourceList = "$migrate/sourceList";
  static const String mangaList = "$migrate/mangaList";
  static const String doMigrate = "$migrate/migrate";
}

abstract class UserUrl {
  static const String user = "/user";
  static const String info = "$user/info";
  static const String register = "$user/register";
  static const String login = "$user/login";
  static const String logout = "$user/logout";
  static const String delete = "$user/delete";
  static const String thirdLogin = "$user/third-login";
}

abstract class SyncUrl {
  static const String sync = "/sync";
  static const String enableSync = "$sync/enableSync";
  static const String disableSync = "$sync/disableSync";
  static const String syncNow = "$sync/syncNow";
  static const String syncNowIfEnable = "$sync/syncNowIfEnable";
  static const String ws = "$sync/ws";
}

abstract class StatsUrl {
  static const String readTime = "/stats/readTime";
}

abstract class BrowseUrl {
  static const String browse = "/browse";
  static const String fetchUrl = "$browse/fetchUrl";
}