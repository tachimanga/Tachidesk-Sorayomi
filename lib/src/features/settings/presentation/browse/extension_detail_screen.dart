// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/search_field.dart';
import '../../../browse_center/presentation/extension/controller/extension_controller.dart';
import '../../../browse_center/presentation/extension/extension_screen.dart';
import '../../../browse_center/presentation/extension/widgets/extension_language_filter_dialog.dart';

class ExtensionDetailScreen extends HookConsumerWidget {
  const ExtensionDetailScreen({
    super.key,
    required this.repoId,
    required this.repoName,
  });

  final int repoId;
  final String repoName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSearch = useState(false);
    return Scaffold(
      appBar: AppBar(
        title: Text(repoName.isNotEmpty ? repoName : context.l10n!.extensions),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showSearch.value = true,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const ExtensionLanguageFilterDialog(),
            ),
            icon: const Icon(Icons.translate_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: kCalculateAppBarBottomSizeV2(
            showTextField: showSearch.value,
          ),
          child: Column(
            children: [
              if (showSearch.value)
                Align(
                  alignment: Alignment.centerRight,
                  child: SearchField(
                    key: const ValueKey(1),
                    initialText: ref.read(extensionQueryProvider),
                    onChanged: (val) =>
                        ref.read(extensionQueryProvider.notifier).update(val),
                    onClose: () => showSearch.value = false,
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ExtensionScreen(
        repoId: repoId,
      ),
    );
  }
}
