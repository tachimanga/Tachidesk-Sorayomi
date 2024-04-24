// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/radio_list_popup.dart';
import '../../../../../../widgets/text_premium.dart';
import '../../../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';

class ReaderPageLayoutTile extends ConsumerWidget {
  const ReaderPageLayoutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageLayout = ref.watch(readerPageLayoutPrefProvider) ??
        DBKeys.readerPageLayout.initial;
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: TextPremium(text: context.l10n!.page_layout),
      subtitle: pageLayout != null ? Text(pageLayout.toLocale(context)) : null,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<ReaderPageLayout>(
          title: context.l10n!.page_layout,
          subTitle: context.l10n!.page_layout_tip,
          optionList: ReaderPageLayout.values,
          optionDisplayName: (value) => value.toLocale(context),
          value: pageLayout,
          onChange: (enumValue) async {
            ref.read(readerPageLayoutPrefProvider.notifier).update(enumValue);
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
