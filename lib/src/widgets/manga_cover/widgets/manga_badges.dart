// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/app_sizes.dart';
import '../../../constants/db_keys.dart';
import '../../../features/manga_book/domain/manga/manga_model.dart';

import '../../../utils/extensions/custom_extensions.dart';
import '../providers/manga_cover_providers.dart';

class MangaBadgesRow extends ConsumerWidget {
  const MangaBadgesRow({
    super.key,
    required this.manga,
    this.needSpacer = false,
    this.showCountBadges = false,
    this.padding,
  });
  final Manga manga;
  final bool needSpacer;
  final bool showCountBadges;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedBadge = ref.watch(downloadedBadgeProvider) ?? DBKeys.downloadedBadge.initial;
    final unreadBadge = ref.watch(unreadBadgeProvider) ?? DBKeys.unreadBadge.initial;
    // final languageBadge = ref.watch(languageBadgeProvider) .ifNull();
    return Padding(
      padding: padding ?? KEdgeInsets.a8.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!showCountBadges && manga.inLibrary.ifNull())
            ClipRRect(
              borderRadius: KBorderRadius.r8.radius,
              child: MangaBadge(
                text: context.l10n!.inLibrary,
                color: context.theme.colorScheme.primary,
                textColor: context.theme.colorScheme.onPrimary,
              ),
            ),
          if (showCountBadges) ...[
            ClipRRect(
              borderRadius: KBorderRadius.r8.radius,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (manga.unreadCount.isGreaterThan(0) && unreadBadge)
                    MangaBadge(
                      text: "${manga.unreadCount ?? 0}",
                      color: context.theme.colorScheme.primary,
                      textColor: context.theme.colorScheme.onPrimary,
                    ),
                  if (manga.downloadCount.isGreaterThan(0) && downloadedBadge)
                    MangaBadge(
                      text: "${manga.downloadCount ?? 0}",
                      color: context.theme.colorScheme.tertiary,
                      textColor: context.theme.colorScheme.onTertiary,
                    ),
                ],
              ),
            ),
            if (needSpacer) const Spacer(),
            // if ((manga.source?.lang?.code) != null && languageBadge)
            //   ClipRRect(
            //     borderRadius: KBorderRadius.r16.radius,
            //     child: Badge(
            //       text: manga.source!.lang!.code!,
            //       color: context.theme.colorScheme.tertiary,
            //       textColor: context.theme.colorScheme.onTertiary,
            //     ),
            //   )
          ],
        ],
      ),
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
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Text(text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
