// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/gen/assets.gen.dart';
import '../../routes/router_config.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/misc/toast/toast.dart';
import '../../widgets/custom_popup_menu_widget.dart';
import '../../widgets/emoticons.dart';
import 'controller/stats_controller.dart';
import 'domain/stats_model.dart';
import 'widgets/read_time_manga_tile.dart';

class ReadTimeStatsScreen extends HookConsumerWidget {
  const ReadTimeStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readTimeStats = ref.watch(readTimeStatsProvider);

    // config
    final readTimeConfig = ref.watch(readTimeConfigProvider);
    final quoteList =
        readTimeConfig.quoteList ?? ["一度会ったことは忘れないものさ、思い出せないだけで。"];
    final quote =
        useMemoized(() => quoteList[Random().nextInt(quoteList.length)]);
    final threshold = readTimeConfig.threshold ?? 0.3;

    // logo
    final remoteShowLogo = ref.watch(remoteShowLogoProvider);
    final localShowLogo = ref.watch(localShowLogoProvider);

    refresh() => ref.refresh(readTimeStatsProvider.future);

    useEffect(() {
      if (!readTimeStats.isLoading) refresh();
      return;
    }, []);

    useEffect(() {
      readTimeStats.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [readTimeStats]);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.reading_insights),
      ),
      body: readTimeStats.showUiWhenData(
        context,
        (data) {
          if (data == null || data.totalSeconds == 0 || data.mangaList.isBlank) {
            return Emoticons(
              text: context.l10n!.history_is_empty,
              button: TextButton(
                onPressed: refresh,
                child: Text(context.l10n!.refresh),
              ),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: ReadTimeHeaderWidget(
                        stats: data,
                        quote: quote,
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ReadTimeMangaTile(
                          manga: data.mangaList![index],
                          threshold: threshold,
                          maxReadDuration: data.mangaList![0].readDuration ?? 0,
                          onPressed: () {
                            if (data.mangaList![index].id != null) {
                              context.push(Routes.getManga(
                                data.mangaList![index].id!,
                              ));
                            }
                          },
                        ),
                        childCount: data.mangaList?.length ?? 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (remoteShowLogo == true && localShowLogo == true) ...[
                Positioned(
                  bottom: 20,
                  right: 16,
                  child: CustomPopupMenuWidget(
                    popupItems: [
                      PopupMenuItem(
                        child: Text(context.l10n!.remove),
                        onTap: () {
                          ref
                              .read(localShowLogoProvider.notifier)
                              .update(false);
                        },
                      ),
                    ],
                    child: Image(
                      width: 100,
                      image: AssetImage(context.isDarkMode
                          ? Assets.icons.lOGOWhite.path
                          : Assets.icons.lOGOBlack.path),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        refresh: refresh,
      ),
    );
  }
}

class ReadTimeHeaderWidget extends HookConsumerWidget {
  const ReadTimeHeaderWidget({
    super.key,
    required this.stats,
    required this.quote,
  });

  final ReadTimeStats stats;
  final String quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readTimeString = stats.totalSeconds.toLocalizedReadTime(context);
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$readTimeString",
              style: context.textTheme.displayMedium,
            ),
            Row(
              children: [
                const Icon(
                  Icons.info_rounded,
                  color: Colors.grey,
                  size: 8,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    context.l10n!.reading_time_tip,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey, fontSize: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              quote,
              style: context.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
