// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../settings/controller/remote_blacklist_controller.dart';
import '../../../../settings/data/config/remote_blacklist_config.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../controller/extension_controller.dart';

class InstallExtensionFile extends ConsumerWidget {
  const InstallExtensionFile({super.key});

  void extensionFilePicker(WidgetRef ref, BuildContext context) async {
    final toast = ref.read(toastProvider(context));
    final blacklistConfig = ref.read(blacklistConfigProvider);
    final commonErrStr = context.l10n!.errorSomethingWentWrong;
    final file = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['apk'], //UTType not support apk, ref: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html#//apple_ref/doc/uid/TP40009259-SW1
    );
    if ((file?.files).isNotBlank) {
      if (context.mounted) {
        toast.show(context.l10n!.installingExtension);
      }
    }
    AsyncValue.guard(() async {
      final singleFile = file?.files.single;
      _checkBlacklist(singleFile, blacklistConfig, commonErrStr);
      await ref
          .read(extensionRepositoryProvider)
          .installExtensionFile(context, file: singleFile);
    }).then(
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

  void _checkBlacklist(
    PlatformFile? platformFile,
    BlacklistConfig blacklistConfig,
    String commonErrStr,
  ) {
    if (platformFile == null) {
      return;
    }
    if (blacklistConfig.blackApkNameList?.isNotEmpty == true) {
      final name = platformFile.name;
      final black = blacklistConfig.blackApkNameList?.contains(name) == true;
      log('file name:$name, black:$black');
      if (black) {
        logEvent3("BLACK:APK:NAME", {"x": name});
        throw commonErrStr;
      }
    }
    if (blacklistConfig.blackApkHashList?.isNotEmpty == true) {
      if (platformFile.path != null) {
        File file = File(platformFile.path!);
        if (file.existsSync()) {
          final sha1Digest = crypto.sha1.convert(file.readAsBytesSync());
          final sha1 = sha1Digest.toString();
          final black =
              blacklistConfig.blackApkHashList?.contains(sha1) == true;
          log('file sha1:$sha1, black:$black');
          if (black) {
            logEvent3("BLACK:APK:HASH", {"x": sha1});
            throw commonErrStr;
          }
        }
      }
    }
  }
}
