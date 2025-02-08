// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../icons/icomoon_icons.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../../widgets/popup_Item_with_icon_child.dart';
import '../../../../widgets/search_field.dart';
import '../../../browse_center/data/source_repository/source_repository.dart';
import '../../../browse_center/presentation/source_manga_list/controller/source_manga_controller.dart';
import '../../../settings/presentation/share/controller/share_controller.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/manga/manga_model.dart';
import 'controller/manga_details_controller.dart';
import 'widgets/edit_manga_category_dialog.dart';
import 'widgets/manga_chapter_download_button.dart';
import 'widgets/manga_start_read_icon.dart';

class MangaDetailsAppBar extends HookConsumerWidget
    implements PreferredSizeWidget {
  const MangaDetailsAppBar({
    super.key,
    required this.mangaId,
    required this.data,
    required this.filteredChapterList,
    required this.selectedChapters,
    required this.animationController,
    required this.refresh,
    required this.mangaRefresh,
    required this.showSearch,
  });

  final String mangaId;
  final Manga? data;
  final AsyncValue<List<Chapter>?> filteredChapterList;
  final ValueNotifier<Map<int, Chapter>> selectedChapters;
  final AnimationController animationController;
  final AsyncValueSetter<bool> refresh;
  final AsyncValueSetter<bool> mangaRefresh;
  final ValueNotifier<bool> showSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    useAnimation(animationController);

    final bgColorTween = ColorTween(
      begin: context.theme.appBarTheme.backgroundColor?.withOpacity(0),
      end: context.theme.appBarTheme.backgroundColor?.withOpacity(1),
    ).animate(animationController).value;

    final textColorTween = ColorTween(
      begin: context.theme.appBarTheme.foregroundColor?.withOpacity(0),
      end: context.theme.appBarTheme.foregroundColor?.withOpacity(1),
    ).animate(animationController).value;

    final queryProvider = mangaChapterListQueryProvider(mangaId: mangaId);
    final searchWidget = showSearch.value
        ? PreferredSize(
            preferredSize: Size.zero,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: SearchField(
                    initialText: ref.read(queryProvider),
                    onChanged: (val) =>
                        ref.read(queryProvider.notifier).update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
              ],
            ),
          )
        : null;

    return selectedChapters.value.isNotEmpty
        ? AppBar(
            leading: IconButton(
              onPressed: () => selectedChapters.value = <int, Chapter>{},
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text(
              context.l10n!.numSelected(selectedChapters.value.length),
            ),
            bottom: searchWidget,
            foregroundColor:
                context.theme.appBarTheme.foregroundColor?.withOpacity(1),
            backgroundColor: context.isTablet || showSearch.value
                ? context.theme.appBarTheme.backgroundColor?.withOpacity(1)
                : bgColorTween,
            actions: [
              IconButton(
                onPressed: () {
                  selectBetween();
                  toast.show(context.l10n!.select_between,
                      gravity: ToastGravity.TOP);
                },
                icon: const Icon(Icons.expand),
              ),
              IconButton(
                onPressed: () {
                  selectAll();
                  toast.show(context.l10n!.select_all,
                      gravity: ToastGravity.TOP);
                },
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                onPressed: () {
                  selectInvert();
                  toast.show(context.l10n!.select_invert,
                      gravity: ToastGravity.TOP);
                },
                icon: const Icon(Icons.flip_to_back_rounded),
              ),
            ],
          )
        : AppBar(
            title: Text(data?.title ?? context.l10n!.manga),
            foregroundColor:
                context.isTablet || showSearch.value ? null : textColorTween,
            backgroundColor: context.isTablet || showSearch.value
                ? context.theme.appBarTheme.backgroundColor?.withOpacity(1)
                : bgColorTween,
            bottom: searchWidget,
            actions: [
              if (context.isTablet) MangaStartReadIcon(mangaId: mangaId),
              AsyncIconButton(
                onPressed: data != null
                    ? () async {
                        if (!context.mounted) {
                          return;
                        }
                        final text = context.l10n!.mangaShareText(
                            data?.author ?? "",
                            data?.realUrl ?? "",
                            data?.title ?? "");
                        pipe.invokeMethod("LogEvent", "SHARE:SHARE_MANGA");
                        (await AsyncValue.guard(() async {
                          await ref.read(shareActionProvider).shareText(
                                text,
                              );
                        }))
                            .showToastOnError(toast);
                      }
                    : null,
                icon: const Icon(Icomoon.shareRounded),
              ),
              if (context.isTablet)
                IconButton(
                  onPressed: () => refresh(true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              if (data?.sourceId != "0")
                MangaChapterDownloadButton(mangaId: mangaId),
              PopupMenuButton(
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.r16.radius,
                ),
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => EditMangaCategoryDialog(
                          mangaId: mangaId,
                          manga: data,
                        ),
                      );
                      mangaRefresh(false);
                    },
                    child: PopupItemWithIconChild(
                      icon: const Icon(Icons.label),
                      label: Text(context.l10n!.editCategory),
                    ),
                  ),
                  if (data?.inLibrary == true) ...[
                    PopupMenuItem(
                      onTap: () async {
                        context.push(
                          Routes.getGlobalSearch(data?.title ?? ""),
                          extra: data,
                        );
                      },
                      child: PopupItemWithIconChild(
                        icon: const Icon(Icomoon.exchange),
                        label: Text(context.l10n!.migrate_action_migrate),
                      ),
                    ),
                  ],
                  if (!context.isTablet)
                    PopupMenuItem(
                      onTap: () => refresh(true),
                      child: PopupItemWithIconChild(
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n!.refresh),
                      ),
                    ),
                  if (filteredChapterList.valueOrNull?.isNotEmpty == true)
                    PopupMenuItem(
                      onTap: () {
                        final i = filteredChapterList.valueOrNull!.first;
                        selectedChapters.value = {if (i.id != null) i.id!: i};
                      },
                      child: PopupItemWithIconChild(
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(context.l10n!.select_chapters),
                      ),
                    ),
                  if (data?.sourceId == "0")
                    PopupMenuItem(
                      onTap: () async {
                        (await AsyncValue.guard(() async {
                          await ref
                              .read(sourceRepositoryProvider)
                              .removeLocalManga(mangaId: mangaId);
                          final now = DateTime.now().millisecondsSinceEpoch;
                          ref
                              .read(
                                  localSourceListRefreshSignalProvider.notifier)
                              .update(now);
                          if (context.mounted) {
                            context.pop();
                          }
                        }))
                            .showToastOnError(toast);
                      },
                      child: PopupItemWithIconChild(
                        icon: const Icon(Icons.delete),
                        label: Text(context.l10n!.delete),
                      ),
                    ),
                ],
              ),
            ],
          );
  }

  void selectBetween() {
    int? firstIndex;
    int? lastIndex;
    final list = [...?filteredChapterList.valueOrNull];
    for (int i = 0; i < list.length; i++) {
      final chapter = list[i];
      if (chapter.id != null &&
          selectedChapters.value.containsKey(chapter.id)) {
        if (firstIndex == null) {
          firstIndex = i;
        } else {
          lastIndex = i;
        }
      }
    }
    if (firstIndex == null) {
      return;
    }
    if (firstIndex == lastIndex || lastIndex == null) {
      lastIndex = list.length - 1;
    }
    selectedChapters.value = {
      for (int i = 0; i < list.length; i++)
        if (i >= firstIndex && i <= lastIndex && list[i].id != null)
          list[i].id!: list[i]
    };
  }

  void selectAll() {
    selectedChapters.value = {
      for (Chapter i in [...?filteredChapterList.valueOrNull])
        if (i.id != null) i.id!: i
    };
  }

  void selectInvert() {
    selectedChapters.value = {
      for (Chapter i in [...?filteredChapterList.valueOrNull])
        if (i.id != null && !selectedChapters.value.containsKey(i.id)) i.id!: i
    };
  }

  @override
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (showSearch.value ? kTextFieldHeight : 0));
}
