// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:math';

import 'package:apple_pencil_double_tap/apple_pencil_double_tap.dart';
import 'package:apple_pencil_double_tap/entities/preferred_action.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/device_providers.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../global_providers/preference_providers.dart';
import '../../../../../icons/icomoon_icons.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/classes/pair/pair_model.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/keyboard_util.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/log.dart' as logger;
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../../widgets/async_buttons/async_ink_well.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../browse_center/domain/browse/browse_model.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../settings/presentation/reader/widgets/reader_apple_pencil_setting/reader_apple_pencil_controller.dart';
import '../../../../settings/presentation/reader/widgets/reader_auto_scroll_tile/reader_auto_scroll_controller.dart';
import '../../../../settings/presentation/reader/widgets/reader_auto_scroll_tile/reader_auto_scroll_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_auto_scroll_tile/reader_long_press_scroll_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_keep_screen_on/reader_keep_screen_on_tile.dart';
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
    required this.initChapterIndexState,
    required this.visibility,
    required this.autoScrollIntervalMs,
    required this.autoScrollDemoMode,
    this.longPressScrolling,
    this.reverse = false,
    this.pageLayout,
    this.continuousMode,
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
  final ValueNotifier<String> initChapterIndexState;
  final ReaderPageLayout? pageLayout;
  final ValueNotifier<bool> visibility;
  final ValueNotifier<int?> autoScrollIntervalMs;
  final ValueNotifier<bool> autoScrollDemoMode;
  final ValueNotifier<bool>? longPressScrolling;
  final bool? continuousMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);
    final deviceInfo = ref.watch(deviceInfoProvider);
    final keepScreenOn = ref.read(readerKeepScreenOnPrefProvider) == true;

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

    final autoPageTimer = useRef<Timer?>(null);
    useEffect(() {
      return () {
        autoPageTimer.value?.cancel();
      };
    }, []);
    useEffect(() {
      if (continuousMode == true) {
        return;
      }
      autoPageTimer.value?.cancel();
      final intervalMs = autoScrollIntervalMs.value;
      if (intervalMs != null) {
        autoPageTimer.value = Timer.periodic(
          Duration(milliseconds: autoScrollTransform(intervalMs)),
              (timer) {
            if (context.mounted) {
              final tick = autoScrollDemoMode.value || !visibility.value;
              if (tick) {
                onNext();
              }
            }
          },
        );
      }
      return;
    }, [autoScrollIntervalMs.value]);

    final invokeScreenOnBefore = useRef<bool>(false);
    useEffect(() {
      if (keepScreenOn) {
        return;
      }
      final intervalMs = autoScrollIntervalMs.value;
      if (intervalMs != null) {
        invokeScreenOnBefore.value = true;
        pipe.invokeMethod("SCREEN_ON", "1");
      }
      if (invokeScreenOnBefore.value == true && intervalMs == null) {
        pipe.invokeMethod("SCREEN_ON", "0");
      }
      return;
    }, [autoScrollIntervalMs.value]);

    useEffect(() {
      _setupPencilListener(ref);
      return;
    }, []);

    final doubleTapZoomIn = ref.watch(readerDoubleTapZoomInProvider);
    final tapDelay = doubleTapZoomIn == true ? 500 : 300;
    final showSourceUrl = ref.watch(showSourceUrlProvider);

    final globeLayout = ref.watch(readerNavigationLayoutKeyProvider) ?? ReaderNavigationLayout.disabled;
    final mangaReaderNavigationLayout = manga.meta?.readerNavigationLayout ?? ReaderNavigationLayout.defaultNavigation;
    final effectNavigationLayout = mangaReaderNavigationLayout == ReaderNavigationLayout.defaultNavigation
        ? globeLayout : mangaReaderNavigationLayout;

    final globalReaderMode = ref.watch(readerModeKeyProvider) ?? ReaderMode.webtoon;

    final mangaReaderMode = manga.meta?.readerMode ?? ReaderMode.defaultReader;
    final effectReaderMode = mangaReaderMode == ReaderMode.defaultReader
        ? globalReaderMode : mangaReaderMode;

    final showReaderModePopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderMode>(
          optionList: ReaderMode.sortedValues,
          optionDisplayName: (value) => value.toLocale(context),
          showDisplaySubName: (value) {
            return value == ReaderMode.defaultReader &&
                globalReaderMode != ReaderMode.defaultReader;
          },
          optionDisplaySubName: (value) => globalReaderMode.toLocale(context),
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
        ReaderAutoScrollTile(
          intervalState: autoScrollIntervalMs,
          continuousMode: continuousMode,
          autoScrollDemoMode: autoScrollDemoMode,
        ),
        if (continuousMode == true) ...[
          ReaderLongPressScrollTile(),
        ],
      ],
    );
    final reverseKey = Directionality.of(context) == TextDirection.ltr ? reverse : !reverse;
    final safeAreaBottom = MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom;

    final smoothInterval = ref.watch(autoSmoothScrollIntervalPrefProvider) ??
        DBKeys.autoSmoothScrollInterval.initial;
    final longPressScrollEnable = ref.watch(longPressScrollPrefProvider) ??
        DBKeys.longPressScroll.initial;
    final previousKeys = reverseKey ? previousKeySetReversed : previousKeySet;
    final nextKeys = reverseKey ? nextKeySetReversed : nextKeySet;

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
                bottom: showSourceUrl == true && chapter.realUrl.isNotBlank == true
                    ? PreferredSize(
                  preferredSize: const Size.fromHeight(22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                      child: AsyncInkWell(
                        onTap: () => launchUrlInWebView(
                          context,
                          ref,
                          UrlFetchInput.ofChapterId(chapter.id ?? 0),
                        ),
                        child: Text(
                          "${chapter.realUrl}",
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ),
                  ),
                )
                    : null,
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
                    icon: const Icon(Icomoon.shareRounded),
                  ),
                  AsyncIconButton(
                    onPressed: () => launchUrlInWebView(
                      context,
                      ref,
                      UrlFetchInput.ofChapterId(chapter.id ?? 0),
                    ),
                    icon: const Icon(Icons.public),
                  ),
                ] : null,
              )
            : null,
        extendBodyBehindAppBar: true,
        extendBody: true,
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
                                ? () => loadPrevOrNextChapter(
                              ref,
                              prevNextChapterPair!.second!,
                              reverse,
                            )
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
                                ? () => loadPrevOrNextChapter(
                              ref,
                              prevNextChapterPair!.first!,
                              !reverse,
                            )
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
                              chapterPut: ChapterModifyInput(
                                mangaId: manga.id,
                                chapterId: chapter.id,
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
                                showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  backgroundColor: context.theme.cardColor,
                                  clipBehavior: Clip.hardEdge,
                                  builder: (context) => Padding(
                                    padding: EdgeInsets.only(
                                        bottom: safeAreaBottom),
                                    child: SingleChildScrollView(child: quickSettings),
                                  ),
                                );
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
        body: FocusWrapper(
                previousKeys: previousKeys,
                nextKeys: nextKeys,
                continuousMode: continuousMode,
                longPressScrollEnable: longPressScrollEnable,
                onPress: (key) {
                  if (previousKeys.contains(key)) {
                    onPrevious();
                  }
                  else if (nextKeys.contains(key)) {
                    onNext();
                  }
                },
                onLongPress: (key) {
                  longPressScrolling?.value = true;
                  if (key == null || nextKeys.contains(key)) {
                    autoScrollIntervalMs.value = smoothInterval;
                  } else {
                    autoScrollIntervalMs.value = -smoothInterval;
                  }
                },
                onLongPressUp: (key) {
                  longPressScrolling?.value = false;
                  autoScrollIntervalMs.value = null;
                },
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
                        final lastScrollDiff = lastTapDownTimestamp - lastScrollTimestamp;
                        final autoScrollEnable = autoScrollIntervalMs.value != null;
                        final tapDownDiff = DateTime.now().millisecondsSinceEpoch - lastTapDownTimestamp;
                        logger.log('lastScrollDiff:$lastScrollDiff tapDownDiff:$tapDownDiff isiOSAppOnMac:${deviceInfo.isiOSAppOnMac}');
                        final tapDownMax = deviceInfo.isiOSAppOnMac ? 500 : 300;
                        if (lastScrollDiff > tapDelay || (autoScrollEnable && tapDownDiff < tapDownMax)) {
                          //print('ContinuousReaderMode toggleVisibility yes');
                          visibility.value = !visibility.value;
                          autoScrollDemoMode.value = false;
                        }
                      },
                      scrollDirection: scrollDirection,
                      onNext: () {
                        if (longPressScrollEnable && continuousMode == true) {
                          final lastScrollDiff = DateTime.now().millisecondsSinceEpoch - lastScrollTimestamp;
                          if (lastScrollDiff > 100) {
                            onNext();
                          }
                        } else {
                          onNext();
                        }
                      },
                      onPrevious: () {
                        if (longPressScrollEnable && continuousMode == true) {
                          final lastScrollDiff = DateTime.now().millisecondsSinceEpoch - lastScrollTimestamp;
                          if (lastScrollDiff > 100) {
                            onPrevious();
                          }
                        } else {
                          onPrevious();
                        }
                      },
                      mangaReaderNavigationLayout: effectNavigationLayout,
                      readerMode: effectReaderMode,
                      child: child,
                    ),
                  ),
                )
            ),
      ),
    );
  }

  void loadPrevOrNextChapter(WidgetRef ref, Chapter chapter, bool nextPage) {
    final initChapterIndex = initChapterIndexState.value;
    initChapterIndexState.value = initChapterIndex;
    final provider = chapterWithIdProvider(mangaId: "${manga.id}",
        chapterIndex: initChapterIndex);
    ref.read(provider.notifier).loadChapter(
      mangaId: "${chapter.mangaId}",
      chapterIndex: "${chapter.index}",
      reset: nextPage,
    );
  }

  void _setupPencilListener(WidgetRef ref) {
    ApplePencilDoubleTap().listen(
      // For iPadOS <17.5
      v1Callback: (PreferredAction preferedAction) {
        logger.log('[PENCIL]Double tap. Prefered action: $preferedAction');
        _onPencilDoubleTap(ref);
      },
      // For iPadOS >=17.5
      onTapAction: (TapAction action) {
        logger.log('[PENCIL]TapAction: $action');
        _onPencilDoubleTap(ref);
      },
      // For iPadOS >=17.5
      onSqueeze: (SqueezeAction action) {
        logger.log('[PENCIL]SqueezeAction: $action');
        if (action.squeezePhase == SqueezePhase.ended) {
          _onPencilSqueeze(ref);
        }
      },
      onError: (e) {
        logger.log('[PENCIL]Error: $e');
      },
    );
  }

  void _onPencilDoubleTap(WidgetRef ref) {
    final action = ref.read(applePencilDoubleTabPrefProvider);
    _preformPencilAction(ref, action);
  }

  void _onPencilSqueeze(WidgetRef ref) {
    final action = ref.read(applePencilSqueezePrefProvider);
    _preformPencilAction(ref, action);
  }

  void _preformPencilAction(WidgetRef ref, ApplePencilActon? action) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    if (!purchaseGate && !testflightFlag) {
      logger.log("skip _preformPencilAction, not premium");
      return;
    }
    if (action == ApplePencilActon.nextPage) {
      onNext();
    } else if (action == ApplePencilActon.previousPage) {
      onPrevious();
    } else if (action == ApplePencilActon.previousChapter) {
      final chapterPair = ref.read(
        getPreviousAndNextChaptersProvider(
          mangaId: "${manga.id}",
          chapterIndex: "${chapter.index}",
        ),
      );
      if (chapterPair?.second != null) {
        loadPrevOrNextChapter(ref, chapterPair!.second!, false);
      }
    } else if (action == ApplePencilActon.nextChapter) {
      final chapterPair = ref.read(
        getPreviousAndNextChaptersProvider(
          mangaId: "${manga.id}",
          chapterIndex: "${chapter.index}",
        ),
      );
      if (chapterPair?.first != null) {
        loadPrevOrNextChapter(ref, chapterPair!.first!, true);
      }
    }
  }
}

enum LongPressState {
  init,
  wait,
  longPressing,
  ;
}

class FocusWrapper extends HookConsumerWidget {
  final Widget child;
  final ValueSetter<LogicalKeyboardKey?>? onPress;
  final ValueSetter<LogicalKeyboardKey?>? onLongPress;
  final ValueSetter<LogicalKeyboardKey?>? onLongPressUp;
  final bool? continuousMode;
  final bool longPressScrollEnable;
  final Set<LogicalKeyboardKey> previousKeys;
  final Set<LogicalKeyboardKey> nextKeys;

  const FocusWrapper({
    super.key,
    required this.child,
    required this.previousKeys,
    required this.nextKeys,
    required this.continuousMode,
    required this.longPressScrollEnable,
    this.onPress,
    this.onLongPress,
    this.onLongPressUp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (continuousMode != true) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (previousKeys.contains(event.logicalKey) ||
                  nextKeys.contains(event.logicalKey))) {
            onPress?.call(event.logicalKey);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: child,
      );
    }

    final state = useRef(LongPressState.init);
    final longPressTimer = useRef<Timer?>(null);
    final pointCount = useRef<int>(0);
    final waitStartTime = useRef<int>(0);
    final autoScrolling = ref.watch(autoScrollingProvider);

    void onPointerDown(LogicalKeyboardKey? key) {
      pointCount.value = pointCount.value + 1;
      //logger.log("[TOUCH]onPointerDown state:${state.value} pointCount:${pointCount.value}");
      if (state.value == LongPressState.init) {
        state.value = LongPressState.wait;
        waitStartTime.value = DateTime.now().millisecondsSinceEpoch;
        //logger.log("[TOUCH] state=WAIT");
        longPressTimer.value = Timer(kLongPressTimeout, () {
          state.value = LongPressState.longPressing;
          //logger.log("[TOUCH] state=LONG_PRESSING");
          onLongPress?.call(key);
          //logger.log("[TOUCH] trigger onLongPress");
        });
      } else if (state.value == LongPressState.wait) {
        if (pointCount.value > 1 &&
            DateTime.now().millisecondsSinceEpoch - waitStartTime.value < 500) {
          longPressTimer.value?.cancel();
          state.value = LongPressState.init;
          //logger.log("[TOUCH] two point cancel");
        }
      }
    }

    void onPointerUp(LogicalKeyboardKey? key) {
      pointCount.value = pointCount.value - 1;
      //logger.log("[TOUCH]onPointerUp state:${state.value} pointCount:${pointCount.value}");
      if (state.value == LongPressState.wait) {
        state.value = LongPressState.init;
        //logger.log("[TOUCH] state=INIT");
        longPressTimer.value?.cancel();
        longPressTimer.value = null;
        onPress?.call(key);
        //logger.log("[TOUCH] trigger onPress");
      } else if (state.value == LongPressState.longPressing &&
          pointCount.value == 0) {
        state.value = LongPressState.init;
        //logger.log("[TOUCH] state=INIT");
        onLongPressUp?.call(key);
        //logger.log("[TOUCH] trigger onLongPressUp");
      }
    }

    useEffect(() {
      return () {
        longPressTimer.value?.cancel();
      };
    }, []);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (autoScrolling) {
          return KeyEventResult.ignored;
        }
        if ((event is KeyDownEvent || event is KeyUpEvent) &&
            (previousKeys.contains(event.logicalKey) ||
                nextKeys.contains(event.logicalKey))) {
          if (event is KeyDownEvent) {
            onPointerDown(event.logicalKey);
          } else {
            onPointerUp(event.logicalKey);
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: longPressScrollEnable && !autoScrolling
          ? Listener(
              onPointerDown: (_) => onPointerDown(null),
              onPointerUp: (_) => onPointerUp(null),
              onPointerCancel: (_) => onPointerUp(null),
              child: child,
            )
          : Listener(child: child),
    );
  }
}

class ReaderView extends HookWidget {
  const ReaderView({
    super.key,
    required this.onTapDown,
    required this.onTap,
    required this.scrollDirection,
    required this.child,
    required this.onNext,
    required this.onPrevious,
    required this.mangaReaderNavigationLayout,
    required this.readerMode,
  });

  final GestureTapDownCallback onTapDown;
  final VoidCallback onTap;
  final Axis scrollDirection;
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
