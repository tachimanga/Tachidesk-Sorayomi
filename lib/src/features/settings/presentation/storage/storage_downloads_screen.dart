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

import '../../../../constants/app_constants.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/endpoints.dart';
import '../../../../constants/enum.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/manga_cover_util.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../../../widgets/server_image.dart';
import '../../../manga_book/data/downloads/downloads_repository.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../appearance/controller/date_format_controller.dart';
import 'controller/stroage_controller.dart';
import 'domain/storage_model.dart';
import 'domain/storage_select_key.dart';
import 'utils/storage_util.dart';
import 'widgets/storage_action_bar.dart';

class StorageDownloadsScreen extends HookConsumerWidget {
  const StorageDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final showSearch = useState(false);

    final infoValue = ref.watch(storageInfoProvider);
    final info = infoValue.valueOrNull;

    final mangaInfoList = ref.watch(downloadedMangaInfoListProvider);
    final downloadedMangaViewModelList =
        ref.watch(downloadedMangaViewModelListFilterProvider);

    refresh() => ref.refresh(downloadedMangaInfoListProvider.future);

    useEffect(() {
      mangaInfoList.showToastOnError(toast, withMicrotask: true);
      return;
    }, [mangaInfoList]);

    final selectedMap =
        useState<Map<SelectKey, StorageDownloadViewModel>?>(null);

    final cacheSize =
        selectedMap.value?.values.fold(0, (p, e) => p + (e.size ?? 0)) ?? 0;

    final working = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.storage_manage_downloads),
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSizeV2(
            showTextField: showSearch.value,
          ),
          child: Column(
            children: [
              if (showSearch.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: SearchField(
                    initialText: ref.read(storageDownloadsQueryProvider),
                    onChanged: (val) => ref
                        .read(storageDownloadsQueryProvider.notifier)
                        .update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => showSearch.value = true,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: mangaInfoList.showUiWhenData(
        context,
        (list) {
          final data = downloadedMangaViewModelList.valueOrNull;
          final showLegacyDownload =
              info?.downloadsV1Size != null && info!.downloadsV1Size! > 0;
          if (data.isNullOrEmpty) {
            if (showLegacyDownload) {
              return _buildLegacyDownloadsTile(context, info);
            }
            return Emoticons(
              text: context.l10n!.downloaded_is_empty,
              button: TextButton(
                onPressed: refresh,
                child: Text(context.l10n!.refresh),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: refresh,
            child: Column(
              children: [
                if (showLegacyDownload) ...[
                  _buildLegacyDownloadsTile(context, info)
                ],
                Expanded(
                  child: ListView.builder(
                    itemCount: data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final e = data![index];
                      final selectKey = SelectKey(e.mangaId, null, null);
                      final selected =
                          selectedMap.value?.containsKey(selectKey) == true;
                      return MangaCoverListTile(
                        e: e,
                        onPressed: () {
                          selectedMap.value =
                              selectedMap.value.toggleKeyNullable(selectKey, e);
                        },
                        selected: selected,
                      );
                    },
                  ),
                ),
                StorageActionBar(
                  onTapSelectAll: selectedMap.value?.length == data?.length
                      ? null
                      : () {
                          selectedMap.value = {
                            for (final i in data!)
                              SelectKey(i.mangaId, null, null): i
                          };
                        },
                  onTapDeselect: selectedMap.value?.isEmpty == true
                      ? null
                      : () {
                          selectedMap.value = {};
                        },
                  onTapRemove: selectedMap.value?.isEmpty == true ||
                          working.value ||
                          cacheSize <= 0
                      ? null
                      : () {
                          _showConfirm(
                            context,
                            ref,
                            toast,
                            working,
                            selectedMap,
                            cacheSize,
                          );
                        },
                  size: cacheSize > 0 ? cacheSize : null,
                ),
              ],
            ),
          );
        },
        refresh: refresh,
      ),
    );
  }

  ListTile _buildLegacyDownloadsTile(BuildContext context, StorageInfo info) {
    return ListTile(
      leading: Icon(Icons.archive),
      title: Text(context.l10n!.storage_legacy_downloads),
      subtitle: Text(
        context.l10n!.storage_legacy_downloads_subtitle,
        style: context.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
      visualDensity: VisualDensity.compact,
      contentPadding: kSettingPadding,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            info.downloadsV1Size.toFormattedSize() ?? "",
            style: context.textTheme.labelLarge,
          ),
          kSettingTrailing,
        ],
      ),
      onTap: () {
        logEvent3("STORAGE:DOWNLOADS:LEGACY:TILE");
        context.push([
          Routes.settings,
          Routes.generalSettings,
          Routes.storageSettings,
          Routes.storageDownloadsSettings,
          Routes.storageDownloadsV1Settings
        ].toPath);
      },
    );
  }

  void _showConfirm(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    ValueNotifier<bool> working,
    ValueNotifier<Map<SelectKey, StorageDownloadViewModel>?> selectedMap,
    int cacheSize,
  ) {
    showDialog(
      context: context,
      builder: (innerCtx) {
        return AlertDialog(
          icon: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 40,
          ),
          content: Text(
            context.l10n!.storage_remove_confirm,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => innerCtx.pop(),
                  child: Text(context.l10n!.cancel),
                ),
                const SizedBox(
                  width: 15,
                ),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    _doRemoveDownloads(
                      context,
                      ref,
                      toast,
                      working,
                      selectedMap,
                      cacheSize,
                    );
                  },
                  child: Text(context.l10n!.storage_remove_label),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _doRemoveDownloads(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    ValueNotifier<bool> working,
    ValueNotifier<Map<SelectKey, StorageDownloadViewModel>?> selectedMap,
    int cacheSize,
  ) async {
    final selectedList = selectedMap.value!.values.toList();
    String? error;
    try {
      logEvent3("STORAGE:DOWNLOADS:REMOVE", {"x": "${selectedList.length}"});
      working.value = true;
      showDialog(
        context: context,
        barrierDismissible: kDebugMode ? true : false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const CenterCircularProgressIndicator(),
            content: Text(
              context.l10n!.storage_removing_label,
              textAlign: TextAlign.center,
            ),
          );
        },
      );
      final mangaIds = selectedList
          .where((e) => e.mangaId != null)
          .map((e) => e.mangaId!)
          .toList();
      if (mangaIds.isNotEmpty) {
        try {
          await ref
              .read(downloadsRepositoryProvider)
              .batchDeleteDownloadedManga(mangaIds);
        } catch (e) {
          error = e.toString();
        }
      }
    } finally {
      if (context.mounted) {
        working.value = false;
        invalidStorageProviders(ref);
        context.pop();
        if (error != null) {
          toast.showError(error);
        } else {
          selectedMap.value = {};
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
                title: Text(context.l10n!.storage_removed_label),
                content: Text(
                  context.l10n!.storage_space_freed_up(
                      cacheSize.toFormattedSize() ?? ""),
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: Text(context.l10n!.got_it),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }
}

class MangaCoverListTile extends ConsumerWidget {
  const MangaCoverListTile({
    super.key,
    required this.e,
    this.onPressed,
    this.selected = false,
  });

  final StorageDownloadViewModel e;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatPref =
        ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;
    final selectedColor = Theme.of(context).colorScheme.primary;

    final Manga manga = Manga(
      id: e.mangaId,
      thumbnailUrl: MangaUrl.thumbnail(e.mangaId ?? 0),
      inLibrary: e.inLibrary,
    );
    return InkWell(
      onTap: onPressed,
      child: Row(
        children: [
          SizedBox(width: 15),
          selected
              ? Icon(Icons.check_circle, color: selectedColor)
              : const Icon(Icons.radio_button_unchecked),
          SizedBox(width: 4),
          Padding(
            padding: KEdgeInsets.a8.size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ServerImage(
                imageUrl: manga.thumbnailUrl ?? "",
                appendApiToUrl: true,
                extInfo: CoverExtInfo.build(manga),
                size: const Size.square(48),
                decodeWidth: 48,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (e.title ?? context.l10n!.unknownManga),
                  style: context.textTheme.titleSmall?.copyWith(height: 1),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  e.lastDownloadAt != null
                      ? "${e.size.toFormattedSize()} • ${e.lastDownloadAt.toLocalizedDaysAgoFromSeconds(
                          dateFormatPref,
                          context,
                        )}"
                      : "${e.size.toFormattedSize()}",
                  style: context.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  e.source != null
                      ? "${e.source?.name}(${e.source?.lang?.code?.toUpperCase()})"
                      : context.l10n!.unknownSource,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.visibility),
            onPressed: () => context.push(Routes.getManga(e.mangaId!)),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }
}
