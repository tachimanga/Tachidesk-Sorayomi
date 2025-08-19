// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';

class StorageActionBar extends ConsumerWidget {
  const StorageActionBar({
    super.key,
    this.size,
    this.onTapSelectAll,
    this.onTapDeselect,
    this.onTapRemove,
  });

  final int? size;

  final VoidCallback? onTapSelectAll;
  final VoidCallback? onTapDeselect;
  final VoidCallback? onTapRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeAreaBottom =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window)
            .padding
            .bottom;
    return Container(
      color: Color.lerp(
        Theme.of(context).colorScheme.surfaceContainer,
        Colors.white,
        Theme.of(context).brightness == Brightness.dark ? 0.05 : 0.3,
      ),
      padding: EdgeInsets.fromLTRB(10, 5, 20, safeAreaBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              children: [
                TextButton(
                  onPressed: onTapSelectAll,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.l10n!.select_all,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onTapDeselect,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    context.l10n!.deselect,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: onTapRemove,
                  child: Text(
                    context.l10n!.storage_remove_label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  size != null
                      ? context.l10n!.estimated(size.toFormattedSize() ?? "")
                      : "",
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
