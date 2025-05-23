// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../features/manga_book/domain/manga/manga_model.dart';
import '../features/manga_book/domain/update_status/update_status_model.dart';
import '../routes/router_config.dart';
import '../utils/extensions/custom_extensions.dart';

enum ReaderMode {
  defaultReader,
  continuousVertical,
  singleHorizontalLTR,
  singleHorizontalRTL,
  continuousHorizontalLTR,
  continuousHorizontalRTL,
  singleVertical,
  webtoon;

  String toLocale(BuildContext context) {
    switch (this) {
      case ReaderMode.defaultReader:
        return context.l10n!.readerModeDefaultReader;
      case ReaderMode.continuousVertical:
        return context.l10n!.readerModeContinuousVertical;
      case ReaderMode.singleHorizontalLTR:
        return context.l10n!.readerModeSingleHorizontalLTR;
      case ReaderMode.singleHorizontalRTL:
        return context.l10n!.readerModeSingleHorizontalRTL;
      case ReaderMode.continuousHorizontalLTR:
        return context.l10n!.readerModeContinuousHorizontalLTR;
      case ReaderMode.continuousHorizontalRTL:
        return context.l10n!.readerModeContinuousHorizontalRTL;
      case ReaderMode.singleVertical:
        return context.l10n!.readerModeSingleVertical;
      case ReaderMode.webtoon:
        return context.l10n!.readerModeWebtoon;
    }
  }

  String toTipText(BuildContext context) {
    if (this == ReaderMode.defaultReader) {
      return ReaderMode.webtoon.toLocale(context);
    }
    return toLocale(context);
  }

  static List<ReaderMode> get sortedValues => [
        defaultReader,
        singleHorizontalLTR,
        singleHorizontalRTL,
        singleVertical,
        continuousHorizontalLTR,
        continuousHorizontalRTL,
        continuousVertical,
        webtoon,
      ];
}

enum ReaderPageLayout {
  singlePage,
  doublePage,
  automatic,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case ReaderPageLayout.singlePage:
        return context.l10n!.page_layout_single;
      case ReaderPageLayout.doublePage:
        return context.l10n!.page_layout_double;
      case ReaderPageLayout.automatic:
        return context.l10n!.page_layout_automatic;
    }
  }
}

enum ReaderNavigationLayout {
  defaultNavigation,
  lShaped,
  rightAndLeft,
  edge,
  kindlish,
  disabled;

  String toLocale(BuildContext context) {
    switch (this) {
      case ReaderNavigationLayout.defaultNavigation:
        return context.l10n!.readerNavigationLayoutDefault;
      case ReaderNavigationLayout.lShaped:
        return context.l10n!.readerNavigationLayoutLShaped;
      case ReaderNavigationLayout.rightAndLeft:
        return context.l10n!.readerNavigationLayoutRightAndLeft;
      case ReaderNavigationLayout.edge:
        return context.l10n!.readerNavigationLayoutEdge;
      case ReaderNavigationLayout.kindlish:
        return context.l10n!.readerNavigationLayoutKindlish;
      case ReaderNavigationLayout.disabled:
        return context.l10n!.readerNavigationLayoutDisabled;
    }
  }
}

enum MangaSort {
  alphabetical,
  lastRead,
  unread,
  latestChapterUploadAt,
  latestChapterFetchAt,
  dateAdded;

  String toLocale(BuildContext context) {
    switch (this) {
      case MangaSort.alphabetical:
        return context.l10n!.mangaSortAlphabetical;
      case MangaSort.dateAdded:
        return context.l10n!.mangaSortDateAdded;
      case MangaSort.unread:
        return context.l10n!.mangaSortUnread;
      case MangaSort.lastRead:
        return context.l10n!.mangaSortLastRead;
      case MangaSort.latestChapterFetchAt:
        return context.l10n!.mangaSortLatestChapterFetch;
      case MangaSort.latestChapterUploadAt:
        return context.l10n!.action_sort_latest_chapter;
    }
  }
}

enum ChapterSort {
  source,
  // uploadDate
  fetchedDate,
  chapterName,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case ChapterSort.source:
        return context.l10n!.chapterSortSource;
      case ChapterSort.fetchedDate:
        return context.l10n!.chapterSortUploadDate;
      case ChapterSort.chapterName:
        return context.l10n!.chapterSortChapterName;
    }
  }
}

enum DisplayMode {
  grid(Icons.grid_view_rounded),
  list(Icons.view_list_rounded),
  descriptiveList(Icons.view_list_rounded),
  ;

  static const List<DisplayMode> sourceDisplayList = [
    DisplayMode.grid,
    DisplayMode.list
  ];

  final IconData icon;
  const DisplayMode(this.icon);

  String toLocale(BuildContext context) {
    switch (this) {
      case DisplayMode.grid:
        return context.l10n!.displayModeGrid;
      case DisplayMode.list:
        return context.l10n!.displayModeList;
      case DisplayMode.descriptiveList:
        return context.l10n!.displayModeDescriptiveList;
    }
  }
}

enum MangaStatus {
  unknown("UNKNOWN", Icons.block_outlined),
  ongoing("ONGOING", Icons.schedule_rounded),
  completed("COMPLETED", Icons.done_all_rounded),
  licensed("LICENSED", Icons.shield_rounded),
  publishingFinished("PUBLISHING_FINISHED", Icons.publish_rounded),
  cancelled("CANCELLED", Icons.cancel_rounded),
  onHiatus("ON_HIATUS", Icons.pause_circle_rounded);

  final IconData icon;
  final String title;
  const MangaStatus(
    this.title,
    this.icon,
  );
  static final _statusMap = <String, MangaStatus>{
    for (MangaStatus status in MangaStatus.values) status.title: status
  };
  static MangaStatus fromJson(String status) =>
      _statusMap[status] ?? MangaStatus.unknown;
  static String toJson(MangaStatus? status) =>
      status?.title ?? MangaStatus.unknown.title;

  String toLocale(BuildContext context) {
    switch (this) {
      case MangaStatus.unknown:
        return context.l10n!.mangaStatusUnknown;
      case MangaStatus.ongoing:
        return context.l10n!.mangaStatusOngoing;
      case MangaStatus.completed:
        return context.l10n!.mangaStatusCompleted;
      case MangaStatus.licensed:
        return context.l10n!.mangaStatusLicensed;
      case MangaStatus.publishingFinished:
        return context.l10n!.mangaStatusPublishingFinished;
      case MangaStatus.cancelled:
        return context.l10n!.mangaStatusCancelled;
      case MangaStatus.onHiatus:
        return context.l10n!.mangaStatusOnHiatus;
    }
  }
}

enum SourceType {
  latest(Icons.new_releases_outlined, Icons.new_releases_rounded),
  popular(Icons.favorite_border_rounded, Icons.favorite_rounded),
  filter(Icons.filter_list_outlined, Icons.filter_list_rounded);

  const SourceType(this.icon, this.selectedIcon);

  final IconData icon;
  final IconData selectedIcon;

  String toLocale(BuildContext context) {
    switch (this) {
      case SourceType.latest:
        return context.l10n!.sourceTypeLatest;
      case SourceType.popular:
        return context.l10n!.sourceTypePopular;
      case SourceType.filter:
        return context.l10n!.sourceTypeFilter;
    }
  }
}

enum BypassStatus {
  start("start"),
  success("succ"),
  timeout("timeout"),
  cancel("stop"),
  unknown("unknown"),
  ;

  final String code;
  const BypassStatus(
    this.code,
  );
  static final _statusMap = <String, BypassStatus>{
    for (BypassStatus status in BypassStatus.values) status.code: status
  };
  static BypassStatus fromCode(String code) =>
      _statusMap[code] ?? BypassStatus.unknown;

  String? toLocale(BuildContext context) {
    switch (this) {
      case BypassStatus.start:
        return context.l10n!.byPassStart;
      case BypassStatus.success:
        return context.l10n!.byPassSuccess;
      case BypassStatus.timeout:
        return context.l10n!.byPassTimeout;
      case BypassStatus.cancel:
        return context.l10n!.byPassCancel;
      case BypassStatus.unknown:
        return null;
    }
  }
}

enum FrequencyEnum {
  off,
  update_6hour,
  update_12hour,
  update_24hour,
  update_48hour,
  update_weekly,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case FrequencyEnum.off:
        return context.l10n!.off;
      case FrequencyEnum.update_6hour:
        return context.l10n!.update_6hour;
      case FrequencyEnum.update_12hour:
        return context.l10n!.update_12hour;
      case FrequencyEnum.update_24hour:
        return context.l10n!.update_24hour;
      case FrequencyEnum.update_48hour:
        return context.l10n!.update_48hour;
      case FrequencyEnum.update_weekly:
        return context.l10n!.update_weekly;
    }
  }
}

enum LockTypeEnum {
  off,
  biometrics,
  passcode,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case LockTypeEnum.off:
        return context.l10n!.off;
      case LockTypeEnum.biometrics:
        return context.l10n!.lock_type_biometrics;
      case LockTypeEnum.passcode:
        return context.l10n!.lock_type_passcode;
    }
  }
}

enum LockIntervalEnum {
  always,
  after_1min,
  after_2min,
  after_5min,
  after_10min,
  never,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case LockIntervalEnum.always:
        return context.l10n!.lock_always;
      case LockIntervalEnum.after_1min:
        return context.l10n!.lock_after_mins(1);
      case LockIntervalEnum.after_2min:
        return context.l10n!.lock_after_mins(2);
      case LockIntervalEnum.after_5min:
        return context.l10n!.lock_after_mins(5);
      case LockIntervalEnum.after_10min:
        return context.l10n!.lock_after_mins(10);
      case LockIntervalEnum.never:
        return context.l10n!.lock_never;
    }
  }
}

enum SecureScreenEnum {
  off,
  incognito,
  always,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case SecureScreenEnum.off:
        return context.l10n!.off;
      case SecureScreenEnum.incognito:
        return context.l10n!.pref_incognito_mode;
      case SecureScreenEnum.always:
        return context.l10n!.always;
    }
  }
}

enum DefaultTabEnum {
  auto(""),
  library(Routes.library),
  updates(Routes.updates),
  browse(Routes.browse),
  history(Routes.history),
  more(Routes.more),
  ;

  final String route;
  const DefaultTabEnum(
    this.route,
  );

  String toLocale(BuildContext context) {
    switch (this) {
      case DefaultTabEnum.auto:
        return context.l10n!.lastOpenedTab;
      case DefaultTabEnum.updates:
        return context.l10n!.updates;
      case DefaultTabEnum.library:
        return context.l10n!.library;
      case DefaultTabEnum.browse:
        return context.l10n!.browse;
      case DefaultTabEnum.history:
        return context.l10n!.history;
      case DefaultTabEnum.more:
        return context.l10n!.more;
    }
  }
}

enum SwipeRightToGoBackMode {
  always,
  disable,
  disableWhenHorizontal,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case SwipeRightToGoBackMode.always:
        return context.l10n!.always;
      case SwipeRightToGoBackMode.disable:
        return context.l10n!.disable;
      case SwipeRightToGoBackMode.disableWhenHorizontal:
        return context.l10n!.disableWhenHorizontal;
    }
  }
}

enum ApplePencilActon {
  previousPage,
  nextPage,
  previousChapter,
  nextChapter,
  none,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case ApplePencilActon.previousPage:
        return context.l10n!.action_previous_page;
      case ApplePencilActon.nextPage:
        return context.l10n!.action_next_page;
      case ApplePencilActon.previousChapter:
        return context.l10n!.action_previous_chapter;
      case ApplePencilActon.nextChapter:
        return context.l10n!.action_next_chapter;
      case ApplePencilActon.none:
        return context.l10n!.action_none;
    }
  }
}

// https://api.flutter.dev/flutter/intl/DateFormat-class.html
// https://en.m.wikipedia.org/wiki/List_of_date_formats_by_country
enum DateFormatEnum {
  yMMMd("yMMMd"),
  yMd("yMd"),
  MMddyy("MM/dd/yy"),
  ddMMyy("dd/MM/yy"),
  yyyyMMdd("yyyy-MM-dd"),
  ddMMMyyyy("dd MMM yyyy"),
  MMMddyyyy("MMM dd, yyyy"),
  ;

  final String code;
  const DateFormatEnum(
    this.code,
  );
}

enum TraceType {
  mangaList,
  mangaSearch,
  mangaDetail,
  chapterList,
  chapterDetail,
  pageImg,
  ;
}

enum DownloadQueueStatus {
  stopped("Stopped"),
  started("Started"),
  ;

  final String code;
  const DownloadQueueStatus(
    this.code,
  );
}

enum TriState {
  include,
  exclude,
  ignore,
  ;

  bool? toBool() {
    switch (this) {
      case TriState.include:
        return true;
      case TriState.exclude:
        return false;
      case TriState.ignore:
        return null;
    }
  }

  static TriState fromBool(bool? value) {
    if (value == null) {
      return TriState.ignore;
    }
    return value ? TriState.include : TriState.exclude;
  }
}

enum SelectMode {
  between,
  all,
  invert,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case SelectMode.between:
        return context.l10n!.select_between;
      case SelectMode.all:
        return context.l10n!.select_all;
      case SelectMode.invert:
        return context.l10n!.select_invert;
    }
  }

  IconData toIcon() {
    switch (this) {
      case SelectMode.between:
        return Icons.expand;
      case SelectMode.all:
        return Icons.select_all_rounded;
      case SelectMode.invert:
        return Icons.flip_to_back_rounded;
    }
  }
}

enum UserAgentTypeEnum {
  defaultWebView,
  mobileWebView,
  desktopWebView,
  mobileSafari,
  desktopSafari,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case UserAgentTypeEnum.defaultWebView:
        return context.l10n!.label_default;
      case UserAgentTypeEnum.mobileWebView:
        return context.l10n!.user_agent_mobile_webview;
      case UserAgentTypeEnum.desktopWebView:
        return context.l10n!.user_agent_desktop_webview;
      case UserAgentTypeEnum.mobileSafari:
        return context.l10n!.user_agent_mobile_safari;
      case UserAgentTypeEnum.desktopSafari:
        return context.l10n!.user_agent_desktop_safari;
    }
  }
}

enum UrlFetchType {
  source,
  manga,
  chapter,
  ;
}

enum ScanlatorFilterType {
  filter,
  priority,
  ;

  static ScanlatorFilterType safeFromIndex(int? index) {
    for (final type in ScanlatorFilterType.values) {
      if (type.index == index) {
        return type;
      }
    }
    return ScanlatorFilterType.filter;
  }

  String toLocale(BuildContext context) {
    switch (this) {
      case ScanlatorFilterType.filter:
        return context.l10n!.scanlator_filter_label;
      case ScanlatorFilterType.priority:
        return context.l10n!.scanlator_priority_label;
    }
  }
}

enum UpdateStatusEnum {
  RUNNING,
  PENDING,
  COMPLETE,
  FAILED,
  SKIPPED, //client
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case UpdateStatusEnum.RUNNING:
        return context.l10n!.running;
      case UpdateStatusEnum.PENDING:
        return context.l10n!.pending;
      case UpdateStatusEnum.COMPLETE:
        return context.l10n!.completed;
      case UpdateStatusEnum.FAILED:
        return context.l10n!.failed;
      case UpdateStatusEnum.SKIPPED:
        return context.l10n!.skipped;
    }
  }

  List<Manga>? fetchMangas(UpdateStatusMap? map) {
    switch (this) {
      case UpdateStatusEnum.RUNNING:
        return map?.running;
      case UpdateStatusEnum.PENDING:
        return map?.pending;
      case UpdateStatusEnum.COMPLETE:
        return map?.completed;
      case UpdateStatusEnum.FAILED:
        return map?.failed;
      case UpdateStatusEnum.SKIPPED:
        return null;
    }
  }

  IconData toIconData() {
    switch (this) {
      case UpdateStatusEnum.RUNNING:
        return Icons.face;
      case UpdateStatusEnum.PENDING:
        return Icons.hourglass_empty;
      case UpdateStatusEnum.COMPLETE:
        return Icons.task_alt;
      case UpdateStatusEnum.FAILED:
        return Icons.error_outline;
      case UpdateStatusEnum.SKIPPED:
        return Icons.skip_next;
    }
  }
}

enum JobErrorCode {
  UPDATE_FAILED,
  FILTERED_BY_EXCLUDE_CATEGORY,
  FILTERED_BY_UPDATE_STRATEGY,
  FILTERED_BY_MANGA_STATUS,
  FILTERED_BY_UNREAD,
  FILTERED_BY_NOT_STARTED,
  ;

  String toLocale(BuildContext context) {
    switch (this) {
      case JobErrorCode.UPDATE_FAILED:
        return context.l10n!.failed;
      case JobErrorCode.FILTERED_BY_EXCLUDE_CATEGORY:
        return context.l10n!.skip_titles_in_excluded_category;
      case JobErrorCode.FILTERED_BY_UPDATE_STRATEGY:
        return context.l10n!.skip_titles_only_fetch_once;
      case JobErrorCode.FILTERED_BY_MANGA_STATUS:
        return context.l10n!.skip_titles_with_completed_status;
      case JobErrorCode.FILTERED_BY_UNREAD:
        return context.l10n!.skip_titles_with_unread_chapters;
      case JobErrorCode.FILTERED_BY_NOT_STARTED:
        return context.l10n!.skip_titles_that_havent_been_read;
    }
  }
}
