// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../custom_circular_progress_indicator.dart';

class AsyncTextButton extends HookWidget {
  const AsyncTextButton({
    super.key,
    this.onPressed,
    required this.child,
    this.showLoading,
    this.enable,
  });

  final AsyncCallback? onPressed;
  final Widget child;
  final bool? showLoading;
  final bool? enable;

  @override
  Widget build(BuildContext context) {
    final running = useState(false);
    return TextButton(
      onPressed: onPressed == null || running.value || enable == false
          ? null
          : () async {
              try {
                running.value = true;
                await onPressed!();
              } finally {
                running.value = false;
              }
            },
      child: running.value && showLoading == true
          ? const MiniCircularProgressIndicator()
          : child,
    );
  }
}
