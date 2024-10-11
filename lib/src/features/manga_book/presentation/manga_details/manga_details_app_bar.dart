// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/async_buttons/async_icon_button.dart';
import '../../../browse_center/data/source_repository/source_repository.dart';
import '../../../browse_center/presentation/source_manga_list/controller/source_manga_controller.dart';
import '../../../settings/presentation/share/controller/share_controller.dart';
import '../../domain/chapter/chapter_model.dart';
import '../../domain/manga/manga_model.dart';
import 'widgets/chapter_filter_icon_button.dart';
import 'widgets/edit_manga_category_dialog.dart';
import 'widgets/manga_chapter_download_button.dart';
import 'widgets/manga_chapter_organizer.dart';
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
  });

  final String mangaId;
  final Manga? data;
  final AsyncValue<List<Chapter>?> filteredChapterList;
  final ValueNotifier<Map<int, Chapter>> selectedChapters;
  final AnimationController animationController;
  final AsyncValueSetter<bool> refresh;
  final AsyncValueSetter<bool> mangaRefresh;

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

    return selectedChapters.value.isNotEmpty
        ? AppBar(
            leading: IconButton(
              onPressed: () => selectedChapters.value = <int, Chapter>{},
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text(
              context.l10n!.numSelected(selectedChapters.value.length),
            ),
            foregroundColor:
                context.theme.appBarTheme.foregroundColor?.withOpacity(1),
            backgroundColor: context.isTablet
                ? context.theme.appBarTheme.backgroundColor?.withOpacity(1)
                : bgColorTween,
            actions: [
              IconButton(
                onPressed: () {
                  selectedChapters.value = {
                    for (Chapter i in [...?filteredChapterList.valueOrNull])
                      if (i.id != null) i.id!: i
                  };
                },
                icon: const Icon(Icons.select_all_rounded),
              ),
              IconButton(
                onPressed: () {
                  selectedChapters.value = {
                    for (Chapter i in [...?filteredChapterList.valueOrNull])
                      if (i.id != null &&
                          !selectedChapters.value.containsKey(i.id))
                        i.id!: i
                  };
                },
                icon: const Icon(Icons.flip_to_back_rounded),
              ),
            ],
          )
        : AppBar(
            title: Text(data?.title ?? context.l10n!.manga),
            foregroundColor: context.isTablet ? null : textColorTween,
            backgroundColor: context.isTablet ? null : bgColorTween,
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
                icon: const Icon(Icons.share_outlined),
              ),
              if (context.isTablet)
                IconButton(
                  onPressed: () => refresh(true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              if (!context.isTablet)
                ChapterFilterIconButton(
                  mangaId: mangaId,
                  icon: IconButton(
                    onPressed: () =>
                        showMangaChapterOrganizer(context, mangaId),
                    icon: const Icon(Icons.filter_list_rounded),
                  ),
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
                    child: Text(context.l10n!.editCategory),
                  ),
                  if (data?.inLibrary == true) ...[
                    PopupMenuItem(
                      onTap: () async {
                        context.push(
                          Routes.getGlobalSearch(data?.title ?? ""),
                          extra: data,
                        );
                      },
                      child: Text(context.l10n!.migrate_action_migrate),
                    ),
                  ],
                  if (!context.isTablet)
                    PopupMenuItem(
                      onTap: () => refresh(true),
                      child: Text(context.l10n!.refresh),
                    ),
                  if (filteredChapterList.valueOrNull?.isNotEmpty == true)
                    PopupMenuItem(
                      onTap: () {
                        final i = filteredChapterList.valueOrNull!.first;
                        selectedChapters.value = {if (i.id != null) i.id!: i};
                      },
                      child: Text(context.l10n!.select_chapters),
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
                      child: Text(context.l10n!.delete),
                    ),
                ],
              ),
            ],
          );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
