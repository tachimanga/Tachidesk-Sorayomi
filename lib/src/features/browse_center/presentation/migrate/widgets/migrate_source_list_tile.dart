// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/server_image.dart';
import '../../../domain/migrate/migrate_model.dart';
import 'migrate_badge.dart';

class MigrateSourceListTile extends ConsumerWidget {
  const MigrateSourceListTile({super.key, required this.migrateSource});

  final MigrateSource migrateSource;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = migrateSource.source;
    if (source == null) {
      return const SizedBox.shrink();
    }
    final localSource = source.lang?.code == 'localsourcelang';
    return ListTile(
      onTap: () async {
        if (source.id == null) return;
        context.push(
          Routes.getMigrateMangaList(
            source.id!,
          ),
          extra: migrateSource,
        );
      },
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 16.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ServerImage(
          imageUrl: source.iconUrl ?? "",
          size: const Size.square(48),
        ),
      ),
      title: localSource
          ? Text(context.l10n!.local_source)
          : Text(source.displayName ?? source.name ?? ""),
      subtitle: localSource
          ? Text(context.l10n!.other_source)
          : (source.lang?.localizedDisplayName(context)).isNotBlank
              ? Text(source.lang?.localizedDisplayName(context) ?? "")
              : null,
      trailing: MigrateBadge(
        text: "${migrateSource.count ?? 0}",
        color: context.theme.colorScheme.primary,
        textColor: context.theme.colorScheme.onPrimary,
      ),
    );
  }
}
