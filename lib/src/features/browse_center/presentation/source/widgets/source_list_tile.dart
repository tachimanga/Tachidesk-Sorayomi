// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/server_image.dart';
import '../../../domain/source/source_model.dart';
import '../controller/source_controller.dart';

class SourceListTile extends ConsumerWidget {
  const SourceListTile({super.key, required this.source});

  final Source source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: (() async {
        if (source.id == null) return;
        ref.read(sourceLastUsedProvider.notifier).update(source.id);
        context.push(Routes.getSourceManga(
          source.id!,
          SourceType.popular,
        ));
      }),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ServerImage(
          imageUrl: source.iconUrl ?? "",
          size: const Size.square(48),
        ),
      ),
      title: Text(source.displayName ?? source.name ?? ""),
      subtitle: (source.lang?.displayName).isNotBlank
          ? Text(source.lang?.displayName ?? "")
          : null,
      trailing: Wrap(
        spacing: 0, // space between two icons
        children: [
          if (source.isConfigurable.ifNull()) ...[
            TextButton(
              onPressed: () async {
                context.push(Routes.getSourcePref(source.id!));
              },
              child: Text(context.l10n!.settings),
            )
          ],
          if (source.supportsLatest.ifNull()) ...[
            TextButton(
              onPressed: () async {
                ref.read(sourceLastUsedProvider.notifier).update(source.id);
                context.push(Routes.getSourceManga(
                  source.id!,
                  SourceType.latest,
                ));
              },
              child: Text(context.l10n!.latest),
            )
          ],
        ],
      ),
    );
  }
}
