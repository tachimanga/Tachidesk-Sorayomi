// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/async_buttons/async_text_icon_button.dart';
import '../../../../browse_center/presentation/migrate/controller/migrate_controller.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/manga/manga_model.dart';
import 'edit_manga_category_dialog.dart';

class MangaAddLibraryButton extends HookConsumerWidget {
  const MangaAddLibraryButton({
    super.key,
    required this.manga,
    required this.refresh,
  });
  final Manga manga;
  final AsyncCallback refresh;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inLibrary = manga.inLibrary == true;
    return AsyncTextIconButton(
      onPressed: () async {
        final val = await AsyncValue.guard(() async {
          if (manga.inLibrary.ifNull()) {
            await ref
                .read(mangaBookRepositoryProvider)
                .removeMangaFromLibrary("${manga.id}");
          } else {
            await showAddToCategoryDialogIfNeeded(context, ref, manga);
          }
          await invokeRefresh(ref);
        });
        if (context.mounted) {
          val.showToastOnError(ref.read(toastProvider(context)));
        }
      },
      onLongPress: () async {
        await showDialog(
          context: context,
          builder: (context) => EditMangaCategoryDialog(
            mangaId: "${manga.id}",
            manga: manga,
          ),
        );
        invokeRefresh(ref);
      },
      style: inLibrary
          ? TextButton.styleFrom(padding: EdgeInsets.zero)
          : TextButton.styleFrom(
              foregroundColor: Colors.grey, padding: EdgeInsets.zero),
      icon: inLibrary
          ? const Icon(Icons.favorite_rounded)
          : const Icon(Icons.favorite_border_outlined),
      label: inLibrary
          ? Text(context.l10n!.inLibrary)
          : Text(context.l10n!.addToLibrary),
    );
  }

  Future<void> invokeRefresh(WidgetRef ref) async {
    await refresh();
    try {
      ref.invalidate(migrateInfoProvider);
    } catch (e) {
      log("refresh migrateInfoProvider err $e");
    }
  }
}
