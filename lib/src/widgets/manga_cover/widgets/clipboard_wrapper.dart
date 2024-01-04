// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart' as ftoast;
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/misc/toast/toast.dart';

class ClipboardWrapper extends ConsumerWidget {
  const ClipboardWrapper({
    super.key,
    required this.text,
    required this.child,
    this.onLongPressed,
  });
  final String? text;
  final Widget child;
  final VoidCallback? onLongPressed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (text.isBlank) {
      return child;
    }
    final toast = ref.read(toastProvider(context));
    return InkWell(
      onTap: () => onCopy(toast, context),
      onLongPress: () {
        if (onLongPressed != null) {
          onLongPressed!();
        } else {
          onCopy(toast, context);
        }
      },
      child: child,
    );
  }

  void onCopy(Toast toast, BuildContext context) {
    Clipboard.setData(
      ClipboardData(text: text!),
    );
    toast.close();
    toast.show(context.l10n!.copyMsg(text!), gravity: ftoast.ToastGravity.TOP);
  }
}
