// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'app_constants.dart';
import 'enum.dart';

enum DBKeys {
  serverUrl('http://127.0.0.1:4567'),
  sourceLanguageFilter(["all", "lastUsed", "en", "localsourcelang"]),
  extensionLanguageFilter(["installed", "update", "en", "all"]),
  sourceLastUsed(null),
  themeMode(ThemeMode.system),
  authType(AuthType.none),
  basicCredentials(null),
  readerMode(ReaderMode.webtoon),
  readerPadding(0.0),
  readerPaddingLandscape(0.0),
  readerMagnifierSize(1.0),
  readerNavigationLayout(ReaderNavigationLayout.disabled),
  invertTap(false),
  enableFileLog(false),
  useSystemProxy(true),
  showPlus(null),
  repoUrl(null),
  installLocalCount(0),
  downloadedBadge(true),
  unreadBadge(true),
  languageBadge(false),
  l10n(null),
  mangaFilterDownloaded(null),
  mangaFilterUnread(null),
  mangaFilterCompleted(null),
  chapterFilterDownloaded(null),
  chapterFilterUnread(null),
  chapterFilterBookmarked(null),
  mangaSort(MangaSort.alphabetical),
  mangaSortDirection(true), // asc=true, dsc=false
  chapterSort(ChapterSort.source),
  chapterSortDirection(false), // asc=true, dsc=false
  libraryDisplayMode(DisplayMode.grid),
  sourceDisplayMode(DisplayMode.grid),
  gridMangaCoverWidth(192.0),
  purchaseDone(false),
  purchaseExpireMs(0),
  purchaseToken(null),
  serverApiUrl('https://api.tachiyomi.workers.dev'),
  autoBackup(true),
  markNeedAskRate(false),
  initLocation(null),
  scrollAnimation(false),
  doubleTapZoomIn(true),
  pinSourceIdList(<String>[]),
  onlySearchPinSource(false),
  disableBypass(false),
  watermarkSwitch(true),
  themeKey('default'),
  themeBlendLevel(10.0),
  themePureBlackDarkMode(false),
  autoBackupFrequency(FrequencyEnum.off),
  autoBackupLimit(2),
  showStatusBar(false),
  defaultTab(DefaultTabEnum.auto),
  swipeRightToGoBackMode(SwipeRightToGoBackMode.always),
  migrateChapterFlag(true),
  migrateCategoryFlag(true),
  migrateTrackFlag(true),
  categoryIdsToUpdate(<String>[]),
  alwaysAskCategoryToUpdate(true),
  defaultCategory(kCategoryAlwaysAskValue),
  lockType(LockTypeEnum.off),
  lockInterval(LockIntervalEnum.always),
  lockPasscode(''),
  secureScreen(SecureScreenEnum.off),
  incognitoMode(false),
  incognitoModeUsed(false),
  dateFormat(DateFormatEnum.yMMMd),
  libraryShowMangaCount(false),
  ;

  const DBKeys(this.initial);

  final dynamic initial;
}

enum DBStoreName { settings }
