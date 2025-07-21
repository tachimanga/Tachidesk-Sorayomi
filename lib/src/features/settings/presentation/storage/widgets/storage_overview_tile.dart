// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../controller/stroage_controller.dart';
import '../utils/storage_util.dart';

class StorageOverviewTile extends ConsumerWidget {
  const StorageOverviewTile({
    super.key,
    required this.title,
    this.size,
  });

  final String title;
  final int? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(title, style: context.textTheme.titleMedium),
      subtitle: size != null
          ? Text(
              size.toFormattedSize() ?? "",
              style: context.textTheme.titleLarge?.copyWith(fontSize: 36),
            )
          : Row(children: [MiniCircularProgressIndicator()]),
      contentPadding: kSettingPadding,
    );
  }
}
