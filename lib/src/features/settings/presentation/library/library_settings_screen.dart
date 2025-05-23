// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/section_title.dart';
import 'widgets/default_categories_select_tile.dart';
import 'widgets/edit_categories_tile.dart';
import 'widgets/manga_auto_refresh_setting_tile.dart';
import 'widgets/update_categories_setting_tile.dart';
import 'widgets/update_skip_titles_setting_tile.dart';

class LibrarySettingsScreen extends ConsumerWidget {
  const LibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.library),
      ),
      body: ListView(
        children: [
          SectionTitle(title: context.l10n!.categories),
          const EditCategoriesTile(),
          const DefaultCategoriesSelectTile(),
          SectionTitle(title: context.l10n!.update),
          if (magic.b7 == true) ...[
            const UpdateSkipTitlesSettingTile(),
            const UpdateCategoriesSettingTile(),
          ],
          const MangaAutoRefreshSettingTile(),
        ],
      ),
    );
  }
}
