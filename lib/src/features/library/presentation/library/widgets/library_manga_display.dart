// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/custom_checkbox_list_tile.dart';
import '../../../../../widgets/manga_cover/providers/manga_cover_providers.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../controller/library_controller.dart';

class LibraryMangaDisplay extends ConsumerWidget {
  const LibraryMangaDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayMode = ref.watch(libraryDisplayModeProvider);
    return ListView(
      children: [
        ListTile(
          title: Text(
            context.l10n!.displayMode,
            style: context.textTheme.labelLarge,
          ),
          dense: true,
        ),
        RadioList<DisplayMode>(
          optionList: DisplayMode.values,
          displayName: (value) => value.toLocale(context),
          value: displayMode ?? DBKeys.libraryDisplayMode.initial,
          onChange: (value) =>
              ref.read(libraryDisplayModeProvider.notifier).update(value),
        ),
        ListTile(
          title: BadgeSectionTitle(),
          dense: true,
        ),
        CustomCheckboxListTile(
          title: context.l10n!.unread,
          provider: unreadBadgeProvider,
          onChanged: ref.read(unreadBadgeProvider.notifier).update,
          tristate: false,
        ),
        CustomCheckboxListTile(
          title: context.l10n!.downloaded,
          provider: downloadedBadgeProvider,
          onChanged: ref.read(downloadedBadgeProvider.notifier).update,
          tristate: false,
        ),
        ListTile(
          title: Text(
            context.l10n!.tabs_header,
            style: context.textTheme.labelLarge,
          ),
          dense: true,
        ),
        CustomCheckboxListTile(
          title: context.l10n!.action_display_show_number_of_items,
          provider: libraryShowMangaCountProvider,
          onChanged: ref.read(libraryShowMangaCountProvider.notifier).update,
          tristate: false,
        ),
      ],
    );
  }
}

class BadgeSectionTitle extends ConsumerWidget {
  const BadgeSectionTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedBadge =
        ref.watch(downloadedBadgeProvider) ?? DBKeys.downloadedBadge.initial;
    final unreadBadge =
        ref.watch(unreadBadgeProvider) ?? DBKeys.unreadBadge.initial;

    return Row(
      children: [
        Text(
          context.l10n!.badges,
          style: context.textTheme.labelLarge,
        ),
        SizedBox(width: 10),
        ClipRRect(
          borderRadius: KBorderRadius.r8.radius,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MangaBadge(
                text: "X",
                color: unreadBadge
                    ? context.theme.colorScheme.primary
                    : Colors.grey,
                textColor: context.theme.colorScheme.onPrimary,
              ),
              MangaBadge(
                text: "Y",
                color: downloadedBadge
                    ? context.theme.colorScheme.tertiary
                    : Colors.grey,
                textColor: context.theme.colorScheme.onTertiary,
              ),
            ],
          ),
        )
      ],
    );
  }
}

class MangaBadge extends StatelessWidget {
  const MangaBadge({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });
  final String text;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(text, style: TextStyle(color: textColor)),
      ),
    );
  }
}