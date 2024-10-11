// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/emoticons.dart';
import '../../../../../widgets/sort_list_tile.dart';
import '../../../../settings/presentation/browse/widgets/mutil_repo_setting/repo_help_button.dart';
import '../controller/library_controller.dart';

class LibraryMangaEmptyView extends ConsumerWidget {
  const LibraryMangaEmptyView({
    super.key,
    required this.refresh,
    required this.categoryId,
    required this.categoryCount,
  });

  final VoidCallback refresh;
  final int categoryId;
  final int categoryCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);

    final unread = ref.watch(libraryMangaFilterUnreadProvider);
    final completed = ref.watch(libraryMangaFilterCompletedProvider);
    final downloaded = ref.watch(libraryMangaFilterDownloadedProvider);

    final existFilters =
        unread != null || completed != null || downloaded != null;

    if (categoryCount == 1) {
      if (!existFilters) {
        return Emoticons(
          text: context.l10n!.library_is_empty,
          button: magic.c4
              ? const RepoHelpButton(
                  icon: false,
                  source: "SRC_LIBRARY",
                )
              : TextButton.icon(
                  onPressed: () => context.go(Routes.browse),
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(context.l10n!.browse),
                ),
        );
      } else {
        return Emoticons(
          text: context.l10n!.library_is_empty,
          button: TextButton(
            onPressed: () => _resetFilters(ref),
            child: Text(context.l10n!.reset_filters),
          ),
        );
      }
    }

    if (!existFilters) {
      return Emoticons(
        text: context.l10n!.noCategoryMangaFound,
        button: TextButton(
          onPressed: refresh,
          child: Text(context.l10n!.refresh),
        ),
      );
    } else {
      return Emoticons(
        text: context.l10n!.noCategoryMangaFound,
        button: TextButton(
          onPressed: () => _resetFilters(ref),
          child: Text(context.l10n!.reset_filters),
        ),
      );
    }
  }

  void _resetFilters(WidgetRef ref) {
    ref.read(libraryMangaFilterUnreadProvider.notifier).update(null);
    ref.read(libraryMangaFilterDownloadedProvider.notifier).update(null);
    ref.read(libraryMangaFilterCompletedProvider.notifier).update(null);
  }
}
