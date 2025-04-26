// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/app_sizes.dart';
import '../../../../../../constants/db_keys.dart';
import '../../../../../../constants/enum.dart';

import '../../../../../../constants/gen/assets.gen.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../../../widgets/radio_list_popup.dart';
import '../../../../../../widgets/text_premium.dart';
import '../../../../../manga_book/presentation/reader/controller/reader_setting_controller.dart';

class ReaderSkipDuplicateChapters extends ConsumerWidget {
  const ReaderSkipDuplicateChapters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.people),
      title: TextPremium(text: context.l10n!.skip_duplicate_chapters),
      subtitle: Text(
        context.l10n!.scanlator_priority_description,
        style: context.textTheme.labelSmall
            ?.copyWith(color: Colors.grey, fontSize: 12),
      ),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        logEvent3("SCANLATOER:SET:PRIORITY:HOWTO");
        showDialog(
          context: context,
          builder: (context) => const ReaderSkipDuplicateChaptersPopup(),
        );
      },
    );
  }
}

class ReaderSkipDuplicateChaptersPopup extends ConsumerWidget {
  const ReaderSkipDuplicateChaptersPopup({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(context.l10n!.how_to_enable_skip_duplicate_chapters),
      contentPadding: KEdgeInsets.h8v16.size,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                context.l10n!.how_to_enable_skip_duplicate_chapters_tips,
                style: context.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Assets.icons.skipChaptersGuide.image(),
          ),
        ],
      ),
      actions: [
        PopButton(popText: context.l10n!.ok),
      ],
    );
  }
}
