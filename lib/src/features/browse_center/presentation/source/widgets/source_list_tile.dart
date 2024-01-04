// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/server_image.dart';
import '../../../domain/source/source_model.dart';
import '../controller/source_controller.dart';

class SourceListTile extends ConsumerWidget {
  const SourceListTile(
      {super.key, required this.source, required this.pinSourceIdSet});

  final Source source;
  final Set<String> pinSourceIdSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final pinned = pinSourceIdSet.contains(source.id ?? '');
    final localSource = source.lang?.code == 'localsourcelang';
    return ListTile(
      onTap: (() async {
        if (source.id == null) return;
        ref.read(sourceLastUsedProvider.notifier).update(source.id);
        context.push(Routes.getSourceManga(
          source.id!,
          SourceType.popular,
        ));
      }),
      contentPadding: const EdgeInsetsDirectional.only(start: 16.0, end: 6.0),
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
      trailing: Wrap(
        spacing: 0, // space between two icons
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (source.isConfigurable.ifNull()) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                context.push(Routes.getSourcePref(source.id!));
              },
            )
          ],
          if (magic.b7 == true)
            IconButton(
              icon: pinned
                  ? const Icon(Icons.push_pin)
                  : const Icon(Icons.push_pin_outlined),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                if (pinned) {
                  pinSourceIdSet.remove(source.id ?? '');
                } else {
                  pinSourceIdSet.add(source.id ?? '');
                }
                ref
                    .read(pinSourceIdListProvider.notifier)
                    .update(pinSourceIdSet.toList());
              },
            ),
          if (source.supportsLatest.ifNull()) ...[
            IconButton(
              icon: const Icon(Icons.new_releases_outlined),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                ref.read(sourceLastUsedProvider.notifier).update(source.id);
                context.push(Routes.getSourceManga(
                  source.id!,
                  SourceType.latest,
                ));
              },
            ),
          ],
        ],
      ),
    );
  }
}
