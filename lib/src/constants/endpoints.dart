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
}

abstract class SettingsUrl {
  static const String about = '$_settings/about';
  static const String checkServerUpdate = '$_settings/check-update';
  static const String uploadSettings = '$_settings/uploadSettings';
  static const String clearCookies = '$_settings/clearCookies';
  static const String _settings = "/settings";
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
  static String categoryId(String mangaId, String categoryId) =>
      "$_manga/$mangaId/category/$categoryId";
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
  static String chapterPageWithIndex({
    required String mangaId,
    required String chapterIndex,
    required String pageIndex,
  }) =>
      "$_manga/$mangaId/chapter/$chapterIndex/page/$pageIndex";

  static const String _manga = "/manga";
}

abstract class HistoryUrl {
  static const String list = "/history/list";
  static const String batchDelete = "/history/batch";
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
}

abstract class BackupUrl {
  static String import = "$_backup/import/file";
  static String validate = "$_backup/validate/file";
  static String export = "$_backup/export/file";

  static const String _backup = "/backup";
}

abstract class ImportUrl {
  static String import = "/import/file";
  static String update = "/import";
}

abstract class SourceUrl {
  static String sourceList = "$_source/list";

  static String withId(String sourceId) => "$_source/$sourceId";
  static String getMangaList(String sourceId, String sourceType, int pageNum) =>
      "$_source/$sourceId/$sourceType/$pageNum";
  static String preferences(String sourceId) =>
      "$_source/$sourceId/preferences";
  static String filters(String sourceId) => "$_source/$sourceId/filters";
  static String search(String sourceId) => "$_source/$sourceId/search";
  static String quickSearch(String sourceId) =>
      "$_source/$sourceId/quick-search";

  static const String _source = "/source";
}

abstract class UpdateUrl {
  static String recentChapters(int pageNo) => "$update/recentChapters/$pageNo";

  static const String update = "/update";
  static const String fetch = "/update/fetch";
  static const String reset = "/update/reset";
  static const String summary = "/update/summary";
}
