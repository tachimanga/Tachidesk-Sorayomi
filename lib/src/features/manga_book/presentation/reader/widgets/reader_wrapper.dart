// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../settings/presentation/reader/widgets/reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_mode_tile/reader_mode_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_navigation_layout_tile/reader_navigation_layout_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_padding_slider/reader_padding_slider.dart';
import '../../../../settings/presentation/reader/widgets/show_status_bar_tile/show_status_bar_tile.dart';
import '../../../../settings/presentation/share/controller/share_controller.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/chapter/chapter_model.dart';
import '../../../domain/chapter_patch/chapter_put_model.dart';
import '../../../domain/manga/manga_model.dart';
import '../../../widgets/chapter_actions/single_chapter_action_icon.dart';
import '../../manga_details/controller/manga_details_controller.dart';
import '../controller/reader_controller.dart';
import '../controller/reader_controller_v2.dart';
import '../controller/reader_setting_controller.dart';
import 'page_number_slider.dart';
import 'reader_navigation_layout/reader_navigation_layout.dart';
import 'reader_page_layout/manga_page_layout_popup.dart';

var lastTapDownTimestamp = 0;
var lastScrollTimestamp = 0;

class NextScrollIntent extends Intent {}

class PreviousScrollIntent extends Intent {}

class ReaderWrapper extends HookConsumerWidget {
  const ReaderWrapper({
    super.key,
    required this.child,
    required this.manga,
    required this.chapter,
    required this.onChanged,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.scrollDirection,
    this.reverse = false,
    this.initChapterIndexState,
    this.pageLayout,
  });
  final Widget child;
  final Manga manga;
  final Chapter chapter;
  final ValueChanged<int> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final int currentIndex;
  final Axis scrollDirection;
  final bool reverse;
  final ValueNotifier<String>? initChapterIndexState;
  final ReaderPageLayout? pageLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);

    final chapterPair = ref.watch(
      getPreviousAndNextChaptersProvider(
        mangaId: "${manga.id}",
        chapterIndex: "${chapter.index}",
      ),
    );
    final prevNextChapterPair = chapterPair != null && reverse
        ? Pair(
            first: chapterPair.second,
            second: chapterPair.first,
          )
        : chapterPair;

    final visibility = useState(false);

    final readerModeText = useMemoized(() {
      final defaultReaderMode = ref.read(readerModeKeyProvider);
      final readerMode = manga.meta?.readerMode ?? defaultReaderMode;
      return readerMode?.toTipText(context) ?? "";
    }, []);
    useEffect(() {
      toast.show(readerModeText, withMicrotask: true);
      return () {
        toast.close(withMicrotask: true);
      };
    }, []);

    final showStatusBar = ref.watch(showStatusBarModeProvider);
    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: visibility.value ? SystemUiOverlay.values : [
            if (showStatusBar == true) SystemUiOverlay.top,
          ]
      );
      return;
    }, [visibility.value]);

    useEffect(() {
      return () {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
      };
    }, []);

    final mangaReaderPadding = ref.watch(readerPaddingWithMangaIdProvider(mangaId: manga.id.toString()));
    final doubleTapZoomIn = ref.watch(readerDoubleTapZoomInProvider);
    final tapDelay = doubleTapZoomIn == true ? 500 : 300;

    final globeLayout = ref.watch(readerNavigationLayoutKeyProvider) ?? ReaderNavigationLayout.disabled;
    final mangaReaderNavigationLayout = manga.meta?.readerNavigationLayout ?? ReaderNavigationLayout.defaultNavigation;
    final effectNavigationLayout = mangaReaderNavigationLayout == ReaderNavigationLayout.defaultNavigation
        ? globeLayout : mangaReaderNavigationLayout;

    final globeReaderMode = ref.watch(readerModeKeyProvider) ?? ReaderMode.webtoon;
    final mangaReaderMode = manga.meta?.readerMode ?? ReaderMode.defaultReader;
    final effectReaderMode = mangaReaderMode == ReaderMode.defaultReader
        ? globeReaderMode : mangaReaderMode;

    final showReaderModePopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderMode>(
          optionList: ReaderMode.values,
          optionDisplayName: (value) => value.toLocale(context),
          showDisplaySubName: (value) {
            return value == ReaderMode.defaultReader &&
                globeReaderMode != ReaderMode.defaultReader;
          },
          optionDisplaySubName: (value) => globeReaderMode.toLocale(context),
          value: mangaReaderMode,
          title: context.l10n!.readerMode,
          onChange: (enumValue) async {
            if (context.mounted) context.pop();
            await AsyncValue.guard(
              () => ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                    mangaId: "${manga.id}",
                    key: MangaMetaKeys.readerMode.key,
                    value: enumValue.name,
                  ),
            );
            ref.invalidate(mangaWithIdProvider(mangaId: "${manga.id}"));
          },
        ),
      ),
      [mangaReaderMode],
    );

    final showPageLayoutPopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => MangaPageLayoutPopup(
          manga: manga,
        ),
      ),
      [manga],
    );

    final showReaderNavigationLayoutPopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderNavigationLayout>(
          optionList: ReaderNavigationLayout.values,
          optionDisplayName: (value) => value.toLocale(context),
          showDisplaySubName: (value) {
            return value == ReaderNavigationLayout.defaultNavigation &&
                globeLayout != ReaderNavigationLayout.defaultNavigation;
          },
          optionDisplaySubName: (value) => globeLayout.toLocale(context),
          title: context.l10n!.readerNavigationLayout,
          value: mangaReaderNavigationLayout,
          onChange: (enumValue) async {
            if (context.mounted) context.pop();
            await AsyncValue.guard(
              () => ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                    mangaId: "${manga.id}",
                    key: MangaMetaKeys.readerNavigationLayout.key,
                    value: enumValue.name,
                  ),
            );
            ref.invalidate(
              mangaWithIdProvider(mangaId: "${manga.id}"),
            );
          },
        ),
      ),
      [mangaReaderNavigationLayout],
    );

    final quickSettings = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.app_settings_alt_outlined),
          title: Text(context.l10n!.readerMode),
          subtitle: Text(mangaReaderMode.toLocale(context)),
          onTap: () {
            context.pop();
            showReaderModePopup();
          },
        ),
        if (pageLayout != null) ...[
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: TextPremium(text: context.l10n!.page_layout),
            subtitle: Text(pageLayout!.toLocale(context)),
            onTap: () {
              context.pop();
              showPageLayoutPopup();
            },
          ),
        ],
        ListTile(
          leading: const Icon(
            Icons.touch_app_rounded,
          ),
          title: Text(
            context.l10n!.readerNavigationLayout,
          ),
          subtitle: Text(mangaReaderNavigationLayout.toLocale(context)),
          onTap: () {
            context.pop();
            showReaderNavigationLayoutPopup();
          },
        ),
        AsyncReaderPaddingSlider(
          mangaId: manga.id.toString(),
        ),
      ],
    );
    final reverseKey = Directionality.of(context) == TextDirection.ltr ? reverse : !reverse;
    final safeAreaBottom = MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom;
    return Theme(
      data: context.theme.copyWith(
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: visibility.value
            ? AppBar(
                title: ListTile(
                  title: (manga.title).isNotBlank
                      ? Text(
                          "${manga.title}",
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  subtitle: (chapter.name).isNotBlank
                      ? Text(
                          "${chapter.name}${chapter.scanlator.withPrefix(" • ") ?? ""}",
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                ),
                elevation: 0,
                backgroundColor: Colors.black.withOpacity(.7),
                actions: chapter.realUrl.isNotBlank ? [
                  AsyncIconButton(
                    onPressed: () async {
                      if (!context.mounted) {
                        return;
                      }
                      final text = context.l10n!.chapterShareText(
                          manga.author ?? "",
                          chapter.name ?? "",
                          chapter.realUrl ?? "",
                          manga.title ?? "");
                      pipe.invokeMethod(
                          "LogEvent", "SHARE:SHARE_CHAPTER");
                      (await AsyncValue.guard(() async {
                        await ref.read(shareActionProvider).shareText(
                          text,
                        );
                      }))
                          .showToastOnError(toast);
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      context.push(Routes.getWebView(chapter.realUrl ?? ""));
                    },
                    icon: const Icon(Icons.public),
                  ),
                ] : null,
              )
            : null,
        extendBodyBehindAppBar: true,
        extendBody: true,
        endDrawerEnableOpenDragGesture: false,
        endDrawer: Drawer(width: kDrawerWidth, child: quickSettings),
        bottomSheet: visibility.value
            ? ExcludeFocus(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Card(
                          color: Colors.black.withOpacity(.7),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: prevNextChapterPair?.second != null
                                ? () {
                                    if (initChapterIndexState != null) {
                                      loadPrevOrNextChapter(ref,
                                          prevNextChapterPair!.second!, reverse);
                                      return;
                                    }
                                    context.pushReplacement(
                                      Routes.getReader(
                                        "${prevNextChapterPair!.second!.mangaId}",
                                        "${prevNextChapterPair.second!.index}",
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                            ),
                          ),
                        ),
                        Expanded(
                          child: PageNumberSlider(
                            currentValue: currentIndex,
                            maxValue: chapter.pageCount ?? 1,
                            onChanged: (index) => onChanged(index),
                            reverse: reverse,
                          ),
                        ),
                        Card(
                          color: Colors.black.withOpacity(.7),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: prevNextChapterPair?.first != null
                                ? () {
                                    if (initChapterIndexState != null) {
                                      loadPrevOrNextChapter(ref,
                                          prevNextChapterPair!.first!, !reverse);
                                      return;
                                    }
                                    context.pushReplacement(
                                      Routes.getReader(
                                        "${prevNextChapterPair!.first!.mangaId}",
                                        "${prevNextChapterPair.first!.index}",
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                        )
                      ],
                    ),
                    KSizedBox.h2.size,
                    Container(
                      color: Colors.black.withOpacity(.7),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, safeAreaBottom > 0 ? max(0, safeAreaBottom - 14) : 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (chapter.index != null &&
                              chapter.bookmarked != null)
                            SingleChapterActionIcon(
                              icon: chapter.bookmarked!
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              chapterIndex: "${chapter.index!}",
                              mangaId: "${manga.id}",
                              chapterPut: ChapterPut(
                                bookmarked: !chapter.bookmarked!,
                              ),
                              refresh: () async {
                                if (manga.id != null && chapter.index != null) {
                                  ref.read(chapterWithIdProvider(
                                    mangaId: "${manga.id!}",
                                    chapterIndex: "${chapter.index!}",
                                  ).notifier).toggleBookmarked();
                                }
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.app_settings_alt_outlined),
                            onPressed: () => showReaderModePopup(),
                          ),
                          if (pageLayout != null) ...[
                            IconButton(
                              icon: const Icon(Icons.menu_book_outlined),
                              onPressed: () => showPageLayoutPopup(),
                            ),
                          ],
                          Builder(builder: (context) {
                            return IconButton(
                              onPressed: () {
                                if (context.isTablet) {
                                  Scaffold.of(context).openEndDrawer();
                                } else {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: context.theme.cardColor,
                                    clipBehavior: Clip.hardEdge,
                                    builder: (context) => Padding(
                                      padding: EdgeInsets.only(bottom: safeAreaBottom),
                                      child: quickSettings,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.settings_rounded),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : null,
        body: Shortcuts(
          shortcuts: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft):
                reverseKey ? NextScrollIntent() : PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                reverseKey ? PreviousScrollIntent() : NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyW):
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyS): NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyA):
                reverseKey ? NextScrollIntent() : PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyD):
                reverseKey ? PreviousScrollIntent() : NextScrollIntent(),
          },
          child: Actions(
            actions: {
              PreviousScrollIntent: CallbackAction<PreviousScrollIntent>(
                onInvoke: (intent) => onPrevious(),
              ),
              NextScrollIntent: CallbackAction<NextScrollIntent>(
                onInvoke: (intent) => onNext(),
              ),
            },
            child: Focus(
              autofocus: true,
                child:
                NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (visibility.value &&
                        notification is UserScrollNotification &&
                        notification.direction == ScrollDirection.reverse) {
                      visibility.value = false;
                    }
                    if (notification is ScrollEndNotification) {
                      //print('ContinuousReaderMode Scroll End');
                      lastScrollTimestamp = DateTime.now().millisecondsSinceEpoch;
                    }
                    return true;
                  },
                  child: RepaintBoundary(
                    child: ReaderView(
                      onTapDown: (e) {
                        lastTapDownTimestamp = DateTime.now().millisecondsSinceEpoch;
                      },
                      onTap: () {
                        final diff = lastTapDownTimestamp - lastScrollTimestamp;
                        //print('ContinuousReaderMode toggleVisibility diff:$diff');
                        if (diff > tapDelay) {
                          //print('ContinuousReaderMode toggleVisibility yes');
                          visibility.value = !visibility.value;
                        }
                      },
                      scrollDirection: scrollDirection,
                      mangaReaderPadding: mangaReaderPadding,
                      onNext: onNext,
                      onPrevious: onPrevious,
                      mangaReaderNavigationLayout: effectNavigationLayout,
                      readerMode: effectReaderMode,
                      child: child,
                    ),
                  ),
                )
            ),
          ),
        ),
      ),
    );
  }

  void loadPrevOrNextChapter(WidgetRef ref, Chapter chapter, bool nextPage) {
    final initChapterIndex = initChapterIndexState!.value;
    initChapterIndexState!.value = initChapterIndex;
    final provider = chapterWithIdProvider(mangaId: "${manga.id}",
        chapterIndex: initChapterIndex);
    ref.read(provider.notifier).loadChapter(
      mangaId: "${chapter.mangaId}",
      chapterIndex: "${chapter.index}",
      nextPage: nextPage,
    );
  }
}

class ReaderView extends HookWidget {
  const ReaderView({
    super.key,
    required this.onTapDown,
    required this.onTap,
    required this.scrollDirection,
    required this.mangaReaderPadding,
    required this.child,
    required this.onNext,
    required this.onPrevious,
    required this.mangaReaderNavigationLayout,
    required this.readerMode,
  });

  final GestureTapDownCallback onTapDown;
  final VoidCallback onTap;
  final Axis scrollDirection;
  final double mangaReaderPadding;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ReaderNavigationLayout mangaReaderNavigationLayout;
  final ReaderMode readerMode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          onTapDown: onTapDown,
          behavior: HitTestBehavior.translucent,
          child: child,
        ),
        ReaderNavigationLayoutWidget(
          onNext: onNext,
          onPrevious: onPrevious,
          navigationLayout: mangaReaderNavigationLayout,
          readerMode: readerMode,
        ),
      ],
    );
  }
}
