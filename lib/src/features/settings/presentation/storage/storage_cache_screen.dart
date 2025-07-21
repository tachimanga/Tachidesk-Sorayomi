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

import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import 'controller/stroage_controller.dart';
import 'utils/storage_util.dart';

class StorageCacheScreen extends HookConsumerWidget {
  const StorageCacheScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));

    final rawInfoValue = ref.watch(storageRawInfoProvider);

    final infoValue = ref.watch(storageInfoProvider);
    final info = infoValue.valueOrNull;

    final imagesSelected = useState(true);
    final coversSelected = useState(false);
    final othersSelected = useState(true);
    final values = [imagesSelected, coversSelected, othersSelected];

    final cacheSize = (imagesSelected.value ? info?.imageCacheSize ?? 0 : 0) +
        (coversSelected.value ? info?.coverCacheSize ?? 0 : 0) +
        (othersSelected.value ? info?.otherCacheSize ?? 0 : 0);

    final working = useState(false);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.clearCache)),
      body: rawInfoValue.showUiWhenData(
        context,
        (data) {
          return ListView(
            children: [
              CacheTile(
                title: context.l10n!.storage_cache_images,
                size: info?.imageCacheSize ?? 0,
                onPressed: () => imagesSelected.value = !imagesSelected.value,
                selected: imagesSelected.value,
              ),
              CacheTile(
                title: context.l10n!.storage_cache_covers,
                size: info?.coverCacheSize ?? 0,
                onPressed: () => coversSelected.value = !coversSelected.value,
                selected: coversSelected.value,
              ),
              CacheTile(
                title: context.l10n!.storage_cache_others,
                size: info?.otherCacheSize ?? 0,
                onPressed: () => othersSelected.value = !othersSelected.value,
                selected: othersSelected.value,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: values.where((e) => e.value).isEmpty ||
                              working.value ||
                              cacheSize <= 0
                          ? null
                          : () async {
                              await _clearCache(
                                context,
                                ref,
                                toast,
                                working,
                                imagesSelected.value,
                                coversSelected.value,
                                othersSelected.value,
                                values,
                                cacheSize,
                              );
                            },
                      child: Text(
                        context.l10n!.clearCache,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      cacheSize > 0
                          ? context.l10n!
                              .estimated(cacheSize.toFormattedSize() ?? "")
                          : "",
                      overflow: TextOverflow.ellipsis,
                      style:
                          context.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                    SizedBox(height: 10),
                    Text(
                      context.l10n!.storage_cache_subtitle,
                      style: context.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clearCache(
    BuildContext context,
    WidgetRef ref,
    Toast toast,
    ValueNotifier<bool> working,
    bool imagesSelected,
    bool coversSelected,
    bool othersSelected,
    List<ValueNotifier<bool>> values,
    int cacheSize,
  ) async {
    String? error;
    try {
      final x = values.map((e) => e.value ? "1" : "0").join("");
      logEvent3("STORAGE:CACHE:CLEAR", {"x": x});

      working.value = true;
      showDialog(
        context: context,
        barrierDismissible: kDebugMode ? true : false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const CenterCircularProgressIndicator(),
            content: Text(
              context.l10n!.storage_cache_clearing,
              textAlign: TextAlign.center,
            ),
          );
        },
      );

      if (imagesSelected) {
        try {
          await _clearImagesCache(ref);
        } catch (e) {
          error = e.toString();
        }
      }
      if (coversSelected) {
        try {
          await _clearCoversCache(ref);
        } catch (e) {
          error = e.toString();
        }
      }
      if (othersSelected) {
        try {
          await _clearOtherCache(ref);
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
          toast.showError(error.toString());
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                icon: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
                title: Text(context.l10n!.cacheCleared),
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

  Future<void> _clearImagesCache(WidgetRef ref) async {
    await ref.read(storageActionProvider).clearCacheDirs([
      "/Library/Caches/libCachedImageData",
      "/Library/Application Support/Tachidesk/thumbnails",
      "/Library/Application Support/Tachidesk/manga-cache",
    ]);
    _clearFlutterImageCache();
  }

  Future<void> _clearCoversCache(WidgetRef ref) async {
    await ref
        .read(storageActionProvider)
        .clearCacheDirs(["/Library/Application Support/Tachidesk/covers"]);
    _clearFlutterImageCache();
  }

  Future<void> _clearOtherCache(WidgetRef ref) async {
    await ref.read(storageActionProvider).clearCacheDirs([
      "/tmp",
      "/Documents/Inbox",
    ]);
    await ref.read(storageActionProvider).clearCacheWebKit();
    await ref.read(storageActionProvider).clearCacheNSCache();
  }

  void _clearFlutterImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

class CacheTile extends StatelessWidget {
  const CacheTile({
    super.key,
    required this.title,
    required this.size,
    required this.onPressed,
    required this.selected,
  });

  final String title;
  final int size;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return ListTile(
      leading: selected
          ? Icon(Icons.check_circle, color: selectedColor)
          : const Icon(Icons.radio_button_unchecked),
      title: Text(title),
      trailing: Text(
        size.toFormattedSize() ?? "",
        style: context.textTheme.labelLarge,
      ),
      onTap: onPressed,
    );
  }
}
