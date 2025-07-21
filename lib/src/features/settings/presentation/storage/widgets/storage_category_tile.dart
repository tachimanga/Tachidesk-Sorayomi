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

class StorageCategoryTile extends ConsumerWidget {
  const StorageCategoryTile({
    super.key,
    required this.title,
    this.size,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final int? size;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Color.lerp(
            Theme.of(context).colorScheme.surfaceContainer,
            Colors.white,
            Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textTheme.titleMedium),
                      SizedBox(height: 2),
                      size != null
                          ? Text(size.toFormattedSize() ?? "",
                              style: context.textTheme.titleLarge)
                          : MiniCircularProgressIndicator(),
                    ],
                  ),
                ),
                if (trailing != null) ...[trailing!],
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: 5),
              Text(
                subtitle ?? "",
                style: context.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
