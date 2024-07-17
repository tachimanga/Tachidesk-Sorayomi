// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/premium_required_tile.dart';
import '../../../../../../widgets/radio_list_popup.dart';
import '../../../../../custom/inapp/purchase_providers.dart';
import '../../../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';
import '../../../../data/manga_book_repository.dart';
import '../../../../domain/manga/manga_model.dart';
import '../../../manga_details/controller/manga_details_controller.dart';

class MangaPageLayoutPopup extends HookConsumerWidget {
  const MangaPageLayoutPopup({
    super.key,
    required this.manga,
  });
  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final layoutProvider =
        readerPageLayoutWithMangaIdProvider(mangaId: "${manga.id}");
    final effectPageLayout = ref.watch(layoutProvider);
    final layoutProviderNotifier = ref.read(layoutProvider.notifier);

    final premiumPageLayout = !purchaseGate &&
        !testflightFlag &&
        effectPageLayout != ReaderPageLayout.singlePage;

    if (premiumPageLayout) {
      useEffect(() {
        return () {
          Future(() {
            pipe.invokeMethod("LogEvent", "READER:LAYOUT:MANGA:RESET");
            layoutProviderNotifier.updateLocal(ReaderPageLayout.singlePage);
          });
        };
      }, []);
    }

    final skipFirstPageProvider =
        readerPageLayoutSkipFirstWithMangaIdProvider(mangaId: "${manga.id}");
    final effectSkipFirstPage = ref.watch(skipFirstPageProvider);

    return RadioListPopup<ReaderPageLayout>(
      title: context.l10n!.page_layout,
      optionList: ReaderPageLayout.values,
      optionDisplayName: (value) => value.toLocale(context),
      value: effectPageLayout,
      onChange: (value) {
        if (purchaseGate || testflightFlag) {
          if (context.mounted) context.pop();
          ref.read(layoutProvider.notifier).update(value);
        } else {
          ref.read(layoutProvider.notifier).updateLocal(value);
        }
      },
      additionWidgets: [
        Padding(
          padding: const EdgeInsets.only(
            top: 10.0,
            left: 10.0,
            right: 10.0,
          ),
          child: SwitchListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            title: Text(
              context.l10n!.page_layout_separate_first_page,
            ),
            onChanged: effectPageLayout != ReaderPageLayout.singlePage
                ? ref.read(skipFirstPageProvider.notifier).update
                : null,
            value: effectSkipFirstPage,
          ),
        ),
        if (premiumPageLayout) ...[
          const PremiumRequiredTile(),
        ],
      ],
    );
  }
}
