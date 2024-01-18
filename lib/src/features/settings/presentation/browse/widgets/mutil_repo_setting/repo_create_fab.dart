// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../utils/extensions/custom_extensions.dart';
import 'add_repo_dialog.dart';

class RepoCreateFab extends HookConsumerWidget {
  const RepoCreateFab({super.key, this.textButtonStyle = false});
  final bool textButtonStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (textButtonStyle) {
      return TextButton.icon(
          onPressed: () {
            showAddRepoDialog(context, ref);
          },
          icon: const Icon(Icons.add_circle_rounded),
          label: Text(context.l10n!.add_repository));
    }
    return FloatingActionButton.extended(
      onPressed: () {
        showAddRepoDialog(context, ref);
      },
      label: Text(context.l10n!.add_repository),
      icon: const Icon(Icons.add_rounded),
    );
  }

  void showAddRepoDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddRepoDialog(),
    );
  }
}
