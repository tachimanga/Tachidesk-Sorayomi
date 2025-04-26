// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../custom_circular_progress_indicator.dart';

class AsyncTextIconButton extends HookWidget {
  const AsyncTextIconButton({
    super.key,
    this.onPressed,
    this.onLongPress,
    this.style,
    required this.icon,
    required this.label,
    this.showLoading,
  });

  final AsyncCallback? onPressed;
  final AsyncCallback? onLongPress;
  final Widget icon;
  final Widget label;
  final bool? showLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final running = useState(false);
    return TextButton.icon(
      onPressed: onPressed == null || running.value
          ? null
          : () async {
              running.value = true;
              await onPressed!();
              running.value = false;
            },
      onLongPress: onLongPress == null || running.value
          ? null
          : () async {
              running.value = true;
              await onLongPress!();
              running.value = false;
            },
      style: style,
      icon: running.value && showLoading == true
          ? const MiniCircularProgressIndicator()
          : icon,
      label: label,
    );
  }
}
