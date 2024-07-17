// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../utils/extensions/custom_extensions.dart';

class TonalFilledButton extends StatelessWidget {
  const TonalFilledButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    if (context.isDarkMode) {
      return FilledButton.tonal(onPressed: onPressed, style: style, child: child);
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}
