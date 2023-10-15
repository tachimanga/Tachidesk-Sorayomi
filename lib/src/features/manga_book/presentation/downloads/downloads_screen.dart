// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/route/route_aware.dart';
import '../../../../widgets/emoticons.dart';
import '../../data/downloads/downloads_repository.dart';
import '../../domain/downloads/downloads_model.dart';
import 'widgets/download_progress_list_tile.dart';
import 'widgets/downloads_fab.dart';

class DownloadsScreen extends HookConsumerWidget {
  const DownloadsScreen({super.key});

  bool showFab(AsyncValue<Downloads> downloads) =>
      (downloads.valueOrNull?.queue).isNotBlank &&
      downloads.valueOrNull!.queue!.any(
        (element) => element.state != "Error" || element.tries != 3,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final downloads = ref.watch(downloadsSocketProvider);
    final magic = ref.watch(getMagicProvider);
    final pipe = ref.watch(getMagicPipeProvider);

    useEffect(() {
      pipe.invokeMethod("SCREEN_ON", "1");
      return () {
        pipe.invokeMethod("SCREEN_ON", "0");
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.downloads),
        actions: [
          if ((downloads.valueOrNull?.queue).isNotBlank)
            IconButton(
              onPressed: () => AsyncValue.guard(
                ref.read(downloadsRepositoryProvider).clearDownloads,
              ),
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
          if (magic.b7)
            IconButton(
              onPressed: () => launchUrlInWeb(context, AppUrls.downloadHelp.url, toast),
              icon: const Icon(Icons.help_rounded),
            ),
        ],
      ),
      floatingActionButton: showFab(downloads)
          ? DownloadsFab(status: downloads.valueOrNull?.status ?? "")
          : null,
      body: Column(children: [
        ListTile(
          title: Text(context.l10n!.recentlyDownloaded),
          leading: const Icon(Icons.download_outlined),
          onTap: () => context.push(
              [Routes.settings, Routes.downloads, Routes.downloaded].toPath),
        ),
        const Divider(),
        Expanded(
            child: downloads.showUiWhenData(
          context,
          (data) {
            if (data.queue == null) {
              return Emoticons(text: context.l10n!.errorSomethingWentWrong);
            } else if (data.queue!.isEmpty) {
              return Emoticons(
                text: context.l10n!.noDownloads,
              );
            } else {
              final downloadsCount = data.queue?.length ?? 0;
              return ListView.builder(
                itemBuilder: (context, index) {
                  if (index == downloadsCount) return KSizedBox.h96.size;
                  final download = data.queue![index];
                  return DownloadProgressListTile(
                    key: ValueKey(
                      "${download.mangaId}${download.chapterIndex}",
                    ),
                    index: index,
                    downloadsCount: downloadsCount,
                    download: download,
                    toast: toast,
                  );
                },
                itemCount: downloadsCount + 1,
              );
            }
          },
          showGenericError: true,
        ))
      ]),
    );
  }
}
