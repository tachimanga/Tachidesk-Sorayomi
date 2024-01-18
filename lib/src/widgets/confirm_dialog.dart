// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../utils/extensions/custom_extensions.dart';

class ConfirmDialog extends ConsumerWidget {
  const ConfirmDialog({
    super.key,
    this.title,
    this.content,
    this.onConfirm,
  });
  final Widget? title;
  final Widget? content;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: title,
      content: content,
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
                onPressed: () => context.pop(),
                child: Text(context.l10n!.cancel)),
            const SizedBox(
              width: 15,
            ),
            TextButton(
                onPressed: onConfirm, child: Text(context.l10n!.confirm)),
          ],
        )
      ],
    );
  }
}
