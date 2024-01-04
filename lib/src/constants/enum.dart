// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../routes/router_config.dart';
import '../utils/extensions/custom_extensions.dart';

enum AuthType {
  none,
  basic;

  String toLocale(BuildContext context) {
    switch (this) {
      case AuthType.none:
        return context.l10n!.authTypeNone;
      case AuthType.basic:
        return context.l10n!.authTypeBasic;
    }
  }
}

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
  dateAdded,
  unread,
  lastRead,
  latestChapterFetchAt;

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
    }
  }
}

enum ChapterSort {
  source,
  fetchedDate;

  String toLocale(BuildContext context) {
    switch (this) {
      case ChapterSort.source:
        return context.l10n!.chapterSortSource;
      case ChapterSort.fetchedDate:
        return context.l10n!.chapterSortFetchedDate;
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
