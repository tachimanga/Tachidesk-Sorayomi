// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../../manga_book/presentation/reader/controller/reader_controller_v2.dart';

class MangaAutoRefreshSettingTile extends ConsumerWidget {
  const MangaAutoRefreshSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.refresh_rounded),
      title: Text(context.l10n!.manga_auto_refresh_title),
      subtitle: Text(context.l10n!.manga_auto_refresh_desc),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        logEvent3("UPDATE:MANGA:AUTO:$value");
        ref.read(autoRefreshMangaProvider.notifier).update(value);
      },
      value: ref.watch(autoRefreshMangaProvider).ifNull(),
    );
  }
}
