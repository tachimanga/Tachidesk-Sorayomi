// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AsyncTextButtonIcon extends HookWidget {
  const AsyncTextButtonIcon({
    super.key,
    required this.isPrimary,
    this.onPressed,
    this.onLongPressed,
    required this.primaryIcon,
    required this.primaryLabel,
    this.primaryStyle,
    this.secondaryIcon,
    this.secondaryLabel,
    this.secondaryStyle,
  });

  final bool isPrimary;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;
  final Widget primaryIcon;
  final Widget primaryLabel;
  final Widget? secondaryIcon;
  final Widget? secondaryLabel;
  final ButtonStyle? primaryStyle;
  final ButtonStyle? secondaryStyle;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: isPrimary ? primaryStyle : secondaryStyle,
      onPressed: onPressed != null
          ? () {
              onPressed!();
            }
          : null,
      onLongPress: onLongPressed,
      icon: (secondaryIcon != null && !isPrimary)
          ? secondaryIcon!
          : primaryIcon,
      label: (secondaryLabel != null && !isPrimary)
          ? secondaryLabel!
          : primaryLabel,
    );
  }
}
