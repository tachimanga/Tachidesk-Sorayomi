// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/manga_cover_util.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';

class MigrateMangaListTile extends ConsumerWidget {
  const MigrateMangaListTile({super.key, required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () {
        context.push(
          Routes.getGlobalSearch(manga.title ?? ""),
          extra: manga,
        );
      },
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 16.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: context.theme.canvasColor,
          child: ServerImage(
            imageUrl: manga.thumbnailUrl ?? "",
            imageData: manga.thumbnailImg,
            extInfo: CoverExtInfo.build(manga),
            size: const Size.square(48),
            decodeWidth: 48,
          ),
        ),
      ),
      title: Text(manga.title ?? ""),
      trailing: PopupMenuButton(
          shape: RoundedRectangleBorder(
            borderRadius: KBorderRadius.r16.radius,
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                onTap: () {
                  context.push(Routes.getManga(manga.id ?? 0));
                },
                child: Text(context.l10n!.migrate_action_show_manga),
              ),
              PopupMenuItem(
                onTap: () {
                  context.push(
                    Routes.getGlobalSearch(manga.title ?? ""),
                    extra: manga,
                  );
                },
                child: Text(context.l10n!.migrate),
              ),
            ];
          }),
    );
  }
}
