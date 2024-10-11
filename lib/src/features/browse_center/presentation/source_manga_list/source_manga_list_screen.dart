// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/enum.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/hooks/paging_controller_hook.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/search_field.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../../data/source_repository/source_repository.dart';
import '../../domain/filter/filter_model.dart';
import '../../domain/source/source_model.dart';
import 'controller/source_manga_controller.dart';
import 'widgets/install_manga_file.dart';
import 'widgets/show_source_manga_filter.dart';
import 'widgets/source_manga_display_icon_popup.dart';
import 'widgets/source_manga_display_view.dart';
import 'widgets/source_manga_filter.dart';
import 'widgets/source_type_selectable_chip.dart';

class SourceMangaListScreen extends HookConsumerWidget {
  const SourceMangaListScreen({
    super.key,
    required this.sourceId,
    required this.sourceType,
    this.initialQuery,
  });
  final String sourceId;
  final SourceType sourceType;
  final String? initialQuery;

  void _fetchPage(
    SourceRepository repository,
    PagingController<int, Manga> controller,
    int pageKey, {
    String? query,
    List<Map<String, dynamic>>? filter,
  }) {
    AsyncValue.guard(
      () => repository.getMangaList(
        sourceId: sourceId,
        sourceType: sourceType,
        pageNum: pageKey,
        query: query,
        filter: filter,
      ),
    ).then(
      (value) => value.whenOrNull(
        data: (recentChaptersPage) {
          try {
            if (recentChaptersPage != null) {
              if (recentChaptersPage.hasNextPage.ifNull()) {
                controller.appendPage(
                  [...?recentChaptersPage.mangaList],
                  pageKey + 1,
                );
              } else {
                controller.appendLastPage([...?recentChaptersPage.mangaList]);
              }
            }
          } catch (e) {
            //
          }
        },
        error: (error, stackTrace) => controller.error = error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final toast = ref.watch(toastProvider(context));

    final sourceRepository = ref.watch(sourceRepositoryProvider);
    final filtersProvider = sourceMangaFilterListProvider(sourceId);
    final _ = ref.watch(filtersProvider);
    final source = ref.watch(sourceProvider(sourceId));

    final query = useState(initialQuery);
    final showSearch = useState(initialQuery.isNotBlank);
    final controller = usePagingController<int, Manga>(firstPageKey: 1);
    final showDirectFlag = ref.watch(showDirectFlagPrefProvider);
    final showSourceUrl = ref.watch(showSourceUrlProvider);

    useEffect(() {
      controller.addPageRequestListener(
        (pageKey) => _fetchPage(
          sourceRepository,
          controller,
          pageKey,
          query: query.value,
          filter: ref.read(filtersProvider.notifier).getAppliedFilter,
        ),
      );
      return;
    }, []);

    if (sourceId == "0") {
      final refreshSignal = ref.watch(localSourceListRefreshSignalProvider);
      useEffect(() {
        controller.refresh();
        return;
      }, [refreshSignal]);
    }

    return source.showUiWhenData(
      context,
      (data) => Scaffold(
        appBar: AppBar(
          title: _buildTitleWidget(
            context,
            data,
            showSourceUrl,
            showDirectFlag,
          ),
          titleSpacing: 0,
          actions: [
            if (sourceId == "0") ...[
              InstallMangaFile(onSuccess: () => controller.refresh()),
            ],
            IconButton(
              onPressed: () => showSearch.value = true,
              icon: const Icon(Icons.search_rounded),
            ),
            const SourceMangaDisplayIconPopup(),
            if (data?.baseUrl?.isNotEmpty ?? false) ...[
              IconButton(
                onPressed: () {
                  context.push(Routes.getWebView(data?.baseUrl ?? ""));
                },
                icon: const Icon(Icons.public),
              ),
            ],
            if (magic.b7 && sourceId == "0") ...[
              IconButton(
                onPressed: () => launchUrlInWeb(
                  context,
                  AppUrls.localSourceHelp.url,
                  toast,
                ),
                icon: const Icon(Icons.help_rounded),
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: kCalculateAppBarBottomSizeV2(
              showTabBar: true,
              showTextField: showSearch.value,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SourceTypeSelectableChip(
                      value: SourceType.popular,
                      groupValue: sourceType,
                      onSelected: (val) {
                        if (sourceType == SourceType.popular) return;
                        context.pushReplacement(
                          Routes.getSourceManga(sourceId, SourceType.popular),
                        );
                      },
                    ),
                    if ((data?.supportsLatest).ifNull())
                      SourceTypeSelectableChip(
                        value: SourceType.latest,
                        groupValue: sourceType,
                        onSelected: (val) {
                          if (sourceType == SourceType.latest) return;
                          context.pushReplacement(
                            Routes.getSourceManga(sourceId, SourceType.latest),
                          );
                        },
                      ),
                    Builder(
                      builder: (context) => SourceTypeSelectableChip(
                        value: SourceType.filter,
                        groupValue: sourceType,
                        onSelected: (val) {
                          context.isTablet
                              ? Scaffold.of(context).openEndDrawer()
                              : showModalBottomSheet(
                                  context: context,
                                  builder: (context) => ShowSourceMangaFilter(
                                      sourceType: sourceType,
                                      sourceId: sourceId,
                                      controller: controller),
                                );
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(height: 0),
                if (showSearch.value)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SearchField(
                      initialText: query.value,
                      onClose: () => showSearch.value = false,
                      autofocus: initialQuery.isBlank,
                      onSubmitted: (val) {
                        if (sourceType == SourceType.filter) {
                          query.value = val;
                          controller.refresh();
                        } else {
                          if (val == null) return;
                          context.pushReplacement(
                            Routes.getSourceManga(
                              sourceId,
                              SourceType.filter,
                              query: val,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        endDrawer: context.isTablet
            ? Drawer(
                width: kDrawerWidth,
                child: Builder(
                  builder: (context) => ShowSourceMangaFilter(
                      sourceType: sourceType,
                      sourceId: sourceId,
                      controller: controller),
                ),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async => controller.refresh(),
          child: SourceMangaDisplayView(controller: controller, source: data),
        ),
      ),
      refresh: () => ref.refresh(sourceProvider(sourceId)),
      wrapper: (body) => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n!.source),
          centerTitle: false,
        ),
        body: body,
      ),
    );
  }

  Widget _buildTitleWidget(
    BuildContext context,
    Source? data,
    bool? showSourceUrl,
    bool? showDirectFlag,
  ) {
    if (showSourceUrl != true) {
      return Text(
        "${data?.direct == true && showDirectFlag == true ? "⚡" : ""}"
        "${data?.displayName ?? context.l10n!.source}",
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${data?.direct == true && showDirectFlag == true ? "⚡" : ""}"
          "${data?.displayName ?? context.l10n!.source}",
          style: context.textTheme.titleMedium,
        ),
        if (data?.baseUrl?.isNotEmpty == true) ...[
          InkWell(
            onTap: () => context.push(Routes.getWebView(data?.baseUrl ?? "")),
            child: Text(
              data?.baseUrl ?? "",
              style: context.textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ),
        ]
      ],
    );
  }
}
