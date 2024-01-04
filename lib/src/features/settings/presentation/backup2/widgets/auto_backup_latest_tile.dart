// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/date_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../domain/backup/backup_model.dart';
import '../controller/auto_backup_controller.dart';

class AutoBackupLatestTile extends ConsumerWidget {
  const AutoBackupLatestTile({
    super.key,
    required this.backupItem,
  });

  final BackupItem backupItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = formatLocalizedDateTime(context, backupItem.createAt ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Text(
        context.l10n!.last_auto_backup_info(date),
        style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
      ),
    );
  }
}
