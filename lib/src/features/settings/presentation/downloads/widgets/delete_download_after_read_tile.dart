// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../manga_book/presentation/downloads/controller/downloads_controller.dart';

class DeleteDownloadAfterReadTile extends HookConsumerWidget {
  const DeleteDownloadAfterReadTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(deleteDownloadAfterReadPrefProvider) == 1;

    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.delete_outline),
      title: TextPremium(text: context.l10n!.remove_after_read),
      onChanged: (value) {
        logEvent3("DOWNLOAD:AUTO:DELETE:$value");
        ref
            .read(deleteDownloadAfterReadPrefProvider.notifier)
            .update(value ? 1 : 0);
        ref
            .read(deleteDownloadAfterReadTodoListProvider.notifier)
            .update(<String>[]);
      },
      value: value,
    );
  }
}
