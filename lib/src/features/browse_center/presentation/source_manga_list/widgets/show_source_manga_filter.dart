// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/app_sizes.dart';

import '../../../../../constants/enum.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../controller/source_manga_controller.dart';
import 'filter_to_widget.dart';

class ShowSourceMangaFilter extends HookConsumerWidget {
  const ShowSourceMangaFilter({
    super.key,
    required this.sourceType,
    required this.sourceId,
    required this.controller,
  });
  final SourceType sourceType;
  final String sourceId;
  final PagingController<int, Manga> controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersProvider = sourceMangaFilterListProvider(sourceId);
    final filterListValue = ref.watch(filtersProvider);

    final filters = useState(filterListValue.valueOrNull);

    useEffect(() {
      final v = filterListValue.valueOrNull;
      if (v != null) {
        filters.value = v;
      }
      return;
    }, [filterListValue]);

    if (filters.value == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
        child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kAppBarBottomHeight),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              TextButton(
                onPressed: () async {
                  await ref.read(filtersProvider.notifier).reset();
                },
                child: Text(context.l10n!.reset),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref
                      .read(filtersProvider.notifier)
                      .updateFilter(filters.value);
                  if (sourceType == SourceType.filter) {
                    context.pop();
                    controller.refresh();
                  } else {
                    context.pushReplacement(
                      Routes.getSourceManga(sourceId, SourceType.filter),
                    );
                  }
                },
                child: Text(context.l10n!.filter),
              ),
            ],
          ),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          final filter = filters.value![index];
          return FilterToWidget(
            key: ValueKey("Filter-${filter.filterState?.name}"),
            filter: filter,
            onChanged: (value) {
              filters.value = ([...filters.value!]..replaceRange(
                  index,
                  index + 1,
                  [value],
                ));
            },
          );
        },
        itemCount: filters.value!.length,
      ),
    ));
  }
}
