// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../routes/router_config.dart';
import '../../../utils/event_util.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/log.dart';
import '../../../utils/misc/toast/toast.dart';
import '../../account/controller/account_controller.dart';
import '../controller/sync_controller.dart';
import '../data/sync_repository.dart';
import '../domain/sync_model.dart';
import 'sync_now_tile.dart';

class SyncInfoWidget extends HookConsumerWidget {
  const SyncInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusValue = ref.watch(syncSocketProvider);
    final status = statusValue.valueOrNull;
    final state = status?.state;
    final counter = status?.counter;
    final userInfoValue = ref.watch(userInfoProvider);
    final userInfo = userInfoValue.valueOrNull;
    log("[SYNC]syncSocket status:$status");

    if (userInfo?.login != true) {
      return IconButton(
        onPressed: () {
          logEvent3("SYNC:SETTING:WIDGET:NOT_LOGIN");
          context.push([Routes.settings, Routes.syncSettings].toPath);
        },
        icon: const Icon(Icons.cloud_outlined),
      );
    }

    if (state == SyncState.running.value) {
      final progress = counter?.toProgressInt() ?? 0;
      return PopupMenuButton(
        icon: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text(
              progress > 0 ? "${counter?.toProgressInt()}%" : "",
              style: context.textTheme.labelSmall?.copyWith(fontSize: 8),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
        padding: EdgeInsets.zero,
        itemBuilder: (context) {
          return [
            const PopupMenuItem(child: SyncNowTile(inSyncWidget: true)),
            PopupMenuItem(child: SyncSettingsTile(state: state)),
          ];
        },
      );
    }

    if (state == SyncState.success.value) {
      return PopupMenuButton(
        icon: const Icon(Icons.cloud_done_outlined),
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
        padding: EdgeInsets.zero,
        itemBuilder: (context) {
          return [
            const PopupMenuItem(child: SyncNowTile(inSyncWidget: true)),
            PopupMenuItem(child: SyncSettingsTile(state: state)),
          ];
        },
      );
    }

    if (state == SyncState.fail.value) {
      return PopupMenuButton(
        icon: const Icon(Icons.sync_problem),
        shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
        padding: EdgeInsets.zero,
        itemBuilder: (context) {
          return [
            const PopupMenuItem(child: SyncNowTile(inSyncWidget: true)),
            PopupMenuItem(child: SyncSettingsTile(state: state)),
          ];
        },
      );
    }

    return PopupMenuButton(
      icon: const Icon(Icons.cloud_outlined),
      shape: RoundedRectangleBorder(borderRadius: KBorderRadius.r16.radius),
      padding: EdgeInsets.zero,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(child: SyncNowTile(inSyncWidget: true)),
          PopupMenuItem(child: SyncSettingsTile(state: state)),
        ];
      },
    );
  }
}

class SyncSettingsTile extends ConsumerWidget {
  const SyncSettingsTile({
    super.key,
    required this.state,
  });

  final String? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.settings),
      title: Text(context.l10n!.sync_settings),
      onTap: () {
        context.pop();
        logEvent3("SYNC:SETTING:WIDGET:$state");
        context.push([Routes.settings, Routes.syncSettings].toPath);
      },
    );
  }
}
