// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../../../data/source_repository/source_repository.dart';
// import '../controller/extension_controller.dart';

class InstallMangaFile extends ConsumerWidget {
  const InstallMangaFile({
    super.key,
    required this.onSuccess
  });

  final VoidCallback onSuccess;

  void extensionFilePicker(WidgetRef ref, BuildContext context) async {
    final toast = ref.read(toastProvider(context));
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'cbz', 'epub'],//sync with source_repository.dart#installMangaFile
    );
    if ((file?.files).isNotBlank) {
      if (context.mounted) {
        toast.show(context.l10n!.installing);
      }
    }
    AsyncValue.guard(() => ref
        .read(sourceRepositoryProvider)
        .installMangaFile(context, file: file?.files.single)).then(
      (result) => result.whenOrNull(
        error: (error, stackTrace) => result.showToastOnError(toast),
        data: (data) {
          onSuccess();
          final cnt = ref.read(installLocalCountProvider);
          ref.read(installLocalCountProvider.notifier).update(cnt != null ? cnt + 1 : 1);
          toast.instantShow("Added");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.add_rounded),
      onPressed: () => extensionFilePicker(ref, context),
    );
  }
}
