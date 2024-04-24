// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/launch_url_in_web.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../utils/purchase.dart';
import '../../../../../widgets/async_buttons/async_text_button_icon.dart';
import '../../../../../widgets/manga_cover/list/manga_cover_descriptive_list_tile.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../../../../settings/presentation/tracking/widgets/tracker_setting_widget.dart';
import '../../../domain/manga/manga_model.dart';
import 'manga_add_library_button.dart';
import 'manga_genre_chip.dart';

class MangaDescription extends HookConsumerWidget {
  const MangaDescription({
    super.key,
    required this.manga,
    required this.refresh,
    this.backgroundImageHeight,
  });
  final Manga manga;
  final AsyncCallback refresh;
  final double? backgroundImageHeight;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(context.isTablet);
    final trackerAvailable = manga.trackers?.isNotEmpty == true;
    final trackerCount = manga.trackers?.where((t) => t.record != null).length;

    final toast = ref.read(toastProvider(context));
    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);
    final freeTrialFlag = ref.watch(freeTrialFlagProvider);
    EdgeInsets padding = MediaQuery.paddingOf(context);

    final mangaInfoWidget = MangaCoverDescriptiveListTile(
      manga: manga,
      showBadges: false,
      enableCoverPopup: true,
      enableTitleCopy: true,
      enableSourceEntrance: true,
      onTitleClicked: (query) => context.push(Routes.getGlobalSearch(query)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        backgroundImageHeight != null
            ? Stack(
                children: [
                  ServerImage(
                    imageUrl: manga.thumbnailUrl ?? "",
                    imageData: manga.thumbnailImg, fit: BoxFit.cover,
                    size: Size.fromHeight(backgroundImageHeight!),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.theme.scaffoldBackgroundColor
                              .withOpacity(0.9),
                          context.theme.scaffoldBackgroundColor
                              .withOpacity(0.7),
                          context.theme.scaffoldBackgroundColor
                              .withOpacity(0.9),
                          context.theme.scaffoldBackgroundColor
                              .withOpacity(1.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: padding.top,
                        ),
                        mangaInfoWidget,
                      ],
                    ),
                  ),
                ],
              )
            : mangaInfoWidget,
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: MangaAddLibraryButton(manga: manga, refresh: refresh),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                      final purchase = await checkPurchase(
                          purchaseGate,
                          testflightFlag,
                          freeTrialFlag,
                          context,
                          toast);
                    if (!purchase) {
                      return;
                    }
                    if (context.mounted && !trackerAvailable) {
                      await context.push(Routes.mangaTrackSetting);
                      refresh();
                      return;
                    }
                    refresh();
                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.theme.cardColor,
                        clipBehavior: Clip.hardEdge,
                          builder: (context) =>
                              TrackerSettingWidget(
                                  mangaId: manga.id.toString(),
                                  refresh: refresh),
                      );
                    }
                  },
                  icon: trackerCount != null && trackerCount > 0
                      ? const Icon(Icons.done_rounded)
                      : const Icon(Icons.sync_outlined),
                  style: trackerCount != null && trackerCount > 0
                      ? TextButton.styleFrom(padding: EdgeInsets.zero)
                      : TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: EdgeInsets.zero),
                  label: trackerCount != null && trackerCount > 0
                      ? Text(context.l10n!.num_trackers(trackerCount))
                      : Text(context.l10n!.tracking),
                ),
              ),
              if (manga.realUrl.isNotBlank)
                Expanded(
                    child: TextButton.icon(
                  onPressed: () {
                    context.push(Routes.getWebView(manga.realUrl ?? ""));
                  },
                  icon: const Icon(Icons.public),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey, padding: EdgeInsets.zero),
                  label: Text(context.l10n!.webView),
                )),
            ],
          ),
        ),
        if (manga.description.isNotBlank)
          Padding(
            padding: KEdgeInsets.a16.size,
            child: DescriptionWrapper(
              isExpanded: isExpanded.value,
              children: [
                Text(
                  "${manga.description}",
                  maxLines: isExpanded.value ? null : 3,
                ),
                InkWell(
                  child: Container(
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: context.theme.scaffoldBackgroundColor.withOpacity(.7),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          context.theme.scaffoldBackgroundColor.withOpacity(0),
                          context.theme.scaffoldBackgroundColor.withOpacity(.3),
                          context.theme.scaffoldBackgroundColor.withOpacity(.5),
                          context.theme.scaffoldBackgroundColor.withOpacity(.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isExpanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                    ),
                  ),
                  onTap: () => isExpanded.value = !isExpanded.value,
                ),
              ],
            ),
          ),
        if (isExpanded.value)
          Padding(
            padding: KEdgeInsets.h16.size,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              // alignment: WrapAlignment.spaceBetween,
              children: [
                ...?manga.genre
                    ?.map<Widget>(
                      (e) => MangaGenreChip(manga: manga, genre: e),
                    )
                    .toList()
              ],
            ),
          )
        else
          Padding(
            padding: KEdgeInsets.h16.size,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...?manga.genre
                      ?.map<Widget>(
                        (e) => Padding(
                          padding: KEdgeInsets.h4.size,
                          child: MangaGenreChip(manga: manga, genre: e),
                        ),
                      )
                      .toList()
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class DescriptionWrapper extends StatelessWidget {
  const DescriptionWrapper({
    super.key,
    required this.isExpanded,
    required this.children,
  });

  final bool isExpanded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return Column(
        children: children,
      );
    }
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: children,
    );
  }
}
