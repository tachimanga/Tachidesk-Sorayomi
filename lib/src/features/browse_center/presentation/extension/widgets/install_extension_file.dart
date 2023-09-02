// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../controller/extension_controller.dart';

class InstallExtensionFile extends ConsumerWidget {
  const InstallExtensionFile({super.key});

  void extensionFilePicker(WidgetRef ref, BuildContext context) async {
    final toast = ref.read(toastProvider(context));
    final file = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['apk'], //UTType not support apk, ref: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1
    );
    if ((file?.files).isNotBlank) {
      if (context.mounted) {
        toast.show(context.l10n!.installingExtension);
      }
    }
    AsyncValue.guard(() => ref
        .read(extensionRepositoryProvider)
        .installExtensionFile(context, file: file?.files.single)).then(
      (result) => result.whenOrNull(
        error: (error, stackTrace) => result.showToastOnError(toast),
        data: (data) {
          ref.invalidate(extensionProvider);
          toast.instantShow(context.l10n!.extensionInstalled);
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
