// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/search_field.dart';
import '../../../manga_book/domain/manga/manga_model.dart';
import '../source/controller/source_controller.dart';
import 'controller/source_quick_search_controller.dart';
import 'widgets/source_quick_search.dart';

class GlobalSearchScreen extends HookConsumerWidget {
  const GlobalSearchScreen(
      {super.key, this.initialQuery, this.migrateSrcManga});

  final String? initialQuery;
  final Manga? migrateSrcManga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final query = useState(initialQuery);
    final autofocus = initialQuery.isBlank == true;
    final onlySearchPinSource = ref.watch(onlySearchPinSourceProvider);
    final quickSearchResult = ref.watch(quickSearchResultsProvider(
        query: query.value, pin: onlySearchPinSource == true));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.globalSearch),
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSizeV2(
            showTextField: true,
            showCheckBox: true,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SearchField(
                  initialText: query.value,
                  onSubmitted: (value) => query.value = value,
                  autofocus: autofocus,
                ),
              ),
              if (magic.b7 == true)
                Row(
                  children: [
                    Checkbox(
                      value: onlySearchPinSource == true,
                      onChanged: (value) {
                        ref
                            .read(onlySearchPinSourceProvider.notifier)
                            .update(value == true);
                      },
                    ),
                    Expanded(
                      child: Text(context.l10n!.onlySearchPinSource),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      body: quickSearchResult.showUiWhenData(
        context,
        (data) => data.isBlank && query.value.isBlank == false
            ? Emoticons(
                text: context.l10n!.noSourcesFound,
                button: TextButton(
                  onPressed: () => ref.invalidate(sourceListProvider),
                  child: Text(context.l10n!.refresh),
                ),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  if (data[index].source.id == null) {
                    return const SizedBox.shrink();
                  } else {
                    return SourceShortSearch(
                      source: data[index].source,
                      mangaList: data[index].mangaList,
                      query: query.value,
                      migrateSrcManga: migrateSrcManga,
                    );
                  }
                },
                itemCount: data.length,
              ),
      ),
    );
  }
}
