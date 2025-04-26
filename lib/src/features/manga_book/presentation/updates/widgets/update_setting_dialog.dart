// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/async_buttons/async_text_button.dart';
import '../../../../settings/presentation/library/widgets/update_categories_setting_tile.dart';
import '../../../../settings/presentation/library/widgets/update_skip_titles_setting_tile.dart';
import '../../../widgets/update_status_fab.dart';

class UpdateSettingDialog extends ConsumerWidget {
  const UpdateSettingDialog({
    super.key,
    this.retryWhenDismiss,
  });

  final bool? retryWhenDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(context.l10n!.settings),
      contentPadding: KEdgeInsets.h8v16.size,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UpdateSkipTitlesSettingTile(),
          const UpdateCategoriesSettingTile(),
        ],
      ),
      actions: [
        AsyncTextButton(
          onPressed: () async {
            if (retryWhenDismiss == true) {
              await retrySkipped(ref);
            }
            if (context.mounted) {
              context.pop();
            }
          },
          child: Text(context.l10n!.close),
        ),
      ],
    );
  }
}
