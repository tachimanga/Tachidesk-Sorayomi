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

class ReaderAdvancedTile extends ConsumerWidget {
  const ReaderAdvancedTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.code_rounded),
      title: Text(context.l10n!.advanced),
      subtitle: Text(context.l10n!.readerAdvancedSubtitle),
      onTap: () => context.push([
        Routes.settings,
        Routes.readerSettings,
        Routes.readerAdvancedSettings
      ].toPath),
    );
  }
}
