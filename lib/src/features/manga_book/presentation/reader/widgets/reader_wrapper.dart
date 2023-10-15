// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../settings/presentation/reader/widgets/reader_padding_slider/reader_padding_slider.dart';
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
  });
  final Widget child;
  final Manga manga;
  final Chapter chapter;
  final ValueChanged<int> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final int currentIndex;
  final Axis scrollDirection;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prevNextChapterPair = ref.watch(
      getPreviousAndNextChaptersProvider(
        mangaId: "${manga.id}",
        chapterIndex: "${chapter.index}",
      ),
    );
    final visibility = useState(true);
    final mangaReaderPadding = ref.watch(readerPaddingWithMangaIdProvider(mangaId: manga.id.toString()));

    final mangaReaderMode = manga.meta?.readerMode ?? ReaderMode.defaultReader;
    final mangaReaderNavigationLayout = manga.meta?.readerNavigationLayout ??
        ReaderNavigationLayout.defaultNavigation;

    final showReaderModePopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderMode>(
          optionList: ReaderMode.values,
          optionDisplayName: (value) => value.toLocale(context),
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

    final showReaderNavigationLayoutPopup = useCallback(
      () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderNavigationLayout>(
          optionList: ReaderNavigationLayout.values,
          optionDisplayName: (value) => value.toLocale(context),
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
          onChanged: (value) {
            AsyncValue.guard(
              () => ref.read(mangaBookRepositoryProvider).patchMangaMeta(
                    mangaId: "${manga.id}",
                    key: MangaMetaKeys.readerPadding.key,
                    value: value,
                  ),
            );
            //ref.invalidate(mangaWithIdProvider(mangaId: "${manga.id}"));
          },
        ),
      ],
    );

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
                actions: [
                  chapter.realUrl.isBlank
                      ? const SizedBox.shrink()
                      : IconButton(
                          onPressed: () async {
                            launchUrlInWeb(
                              context,
                              (chapter.realUrl ?? ""),
                              ref.read(toastProvider(context)),
                            );
                          },
                          icon: const Icon(Icons.public),
                        )
                ],
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
                                ? () => context.pushReplacement(
                                      Routes.getReader(
                                        "${prevNextChapterPair!.second!.mangaId}",
                                        "${prevNextChapterPair.second!.index}",
                                      ),
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
                          ),
                        ),
                        Card(
                          color: Colors.black.withOpacity(.7),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: prevNextChapterPair?.first != null
                                ? () => context.pushReplacement(
                                      Routes.getReader(
                                        "${prevNextChapterPair!.first!.mangaId}",
                                        "${prevNextChapterPair.first!.index}",
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                        )
                      ],
                    ),
                    KSizedBox.h8.size,
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
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowRight):
                NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyW):
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyS): NextScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyA):
                PreviousScrollIntent(),
            const SingleActivator(LogicalKeyboardKey.keyD): NextScrollIntent(),
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
                    if (notification is ScrollEndNotification) {
                      //print('ContinuousReaderMode Scroll End');
                      lastScrollTimestamp = DateTime.now().millisecondsSinceEpoch;
                    }
                    return true;
                  },
                  child: RepaintBoundary(
                    child: ReaderView(
                      toggleVisibility: () {
                        final now = DateTime.now().millisecondsSinceEpoch;
                        final diff = now - lastScrollTimestamp;
                        //print('ContinuousReaderMode toggleVisibility diff:$diff');
                        if (diff > 300) {
                          //print('ContinuousReaderMode toggleVisibility yes');
                          visibility.value = !visibility.value;
                        }
                      },
                      scrollDirection: scrollDirection,
                      mangaReaderPadding: mangaReaderPadding,
                      onNext: onNext,
                      onPrevious: onPrevious,
                      mangaReaderNavigationLayout: mangaReaderNavigationLayout,
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
}

class ReaderView extends HookWidget {
  const ReaderView({
    super.key,
    required this.toggleVisibility,
    required this.scrollDirection,
    required this.mangaReaderPadding,
    required this.child,
    required this.onNext,
    required this.onPrevious,
    required this.mangaReaderNavigationLayout,
  });

  final VoidCallback toggleVisibility;
  final Axis scrollDirection;
  final double mangaReaderPadding;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ReaderNavigationLayout mangaReaderNavigationLayout;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: toggleVisibility,
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: context.height *
                  (scrollDirection != Axis.vertical ? mangaReaderPadding : 0),
              horizontal: context.width *
                  (scrollDirection == Axis.vertical ? mangaReaderPadding : 0),
            ),
            child: child,
          ),
        ),
        ReaderNavigationLayoutWidget(
          onNext: onNext,
          onPrevious: onPrevious,
          navigationLayout: mangaReaderNavigationLayout,
        ),
      ],
    );
  }
}
