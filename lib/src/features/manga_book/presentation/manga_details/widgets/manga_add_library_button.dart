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

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../utils/purchase.dart';
import '../../../../../widgets/async_buttons/async_text_button_icon.dart';
import '../../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../../settings/presentation/library/controller/category_settings_controller.dart';
import '../../../../settings/presentation/tracking/widgets/tracker_setting_widget.dart';
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
    final alwaysAsk =
        ref.watch(defaultCategoryPrefProvider) == kCategoryAlwaysAskValue;
    return AsyncTextButtonIcon(
      onPressed: () async {
        final val = await AsyncValue.guard(() async {
          if (manga.inLibrary.ifNull()) {
            await ref
                .read(mangaBookRepositoryProvider)
                .removeMangaFromLibrary("${manga.id}");
          } else {
            if (alwaysAsk) {
              final categoryList =
                  await ref.watch(categoryControllerProvider.future);
              final existCustomCategory = categoryList
                      ?.where((e) => e.id != null && e.id != 0)
                      .isNotEmpty ==
                  true;
              if (existCustomCategory) {
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (context) => EditMangaCategoryDialog(
                      mangaId: "${manga.id}",
                      title: "${manga.title}",
                    ),
                  );
                  refresh();
                }
                return;
              }
            }
            await ref
                .read(mangaBookRepositoryProvider)
                .addMangaToLibrary("${manga.id}");
          }
          await refresh();
        });
        if (context.mounted) {
          val.showToastOnError(ref.read(toastProvider(context)));
        }
      },
      onLongPressed: () async {
        await showDialog(
          context: context,
          builder: (context) => EditMangaCategoryDialog(
            mangaId: "${manga.id}",
            title: "${manga.title}",
          ),
        );
        refresh();
      },
      isPrimary: manga.inLibrary.ifNull(),
      primaryIcon: const Icon(Icons.favorite_rounded),
      primaryStyle: TextButton.styleFrom(padding: EdgeInsets.zero),
      secondaryIcon: const Icon(Icons.favorite_border_outlined),
      secondaryStyle: TextButton.styleFrom(
          foregroundColor: Colors.grey, padding: EdgeInsets.zero),
      primaryLabel: Text(context.l10n!.inLibrary),
      secondaryLabel: Text(context.l10n!.addToLibrary),
    );
  }
}
