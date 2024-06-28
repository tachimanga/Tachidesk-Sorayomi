// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/premium_required_tile.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../../manga_book/presentation/downloads/controller/downloads_controller.dart';
import '../../../manga_book/presentation/downloads/widgets/downloads_parallel_button.dart';
import 'widgets/delete_download_after_read_tile.dart';

class DownloadSettingScreen extends HookConsumerWidget {
  const DownloadSettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final autoDelete = ref.watch(deleteDownloadAfterReadPrefProvider) == 1;
    final premiumAutoDelete = !purchaseGate && !testflightFlag && autoDelete;

    return WillPopScope(
        onWillPop: premiumAutoDelete
            ? () async {
                if (premiumAutoDelete) {
                  logEvent3("DOWNLOAD:AUTO:DELETE:RESET");
                  ref
                      .read(deleteDownloadAfterReadPrefProvider.notifier)
                      .update(0);
                }
                return true;
              }
            : null,
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n!.download_settings),
          ),
          body: ListView(
            children: [
              const DownloadsParallelSettingTile(),
              const DeleteDownloadAfterReadTile(),
              if (premiumAutoDelete) ...[
                const PremiumRequiredTile(),
              ],
            ],
          ),
        ));
  }
}
