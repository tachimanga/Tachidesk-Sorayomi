// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../controller/edit_repo_controller.dart';

class EditRepoTile extends ConsumerWidget {
  const EditRepoTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(repoCountProvider);
    return ListTile(
      title: Text(context.l10n!.extension_repo),
      subtitle: Text(count == 1
          ? context.l10n!.one_repository
          : context.l10n!.num_repositories(count)),
      leading: const Icon(Icons.extension_rounded),
      onTap: () => context.push([
        Routes.settings,
        Routes.browseSettings,
        Routes.editRepo
      ].toPath),
    );
  }
}
