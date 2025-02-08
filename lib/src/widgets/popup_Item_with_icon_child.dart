// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../utils/extensions/custom_extensions.dart';

class PopupItemWithIconChild extends StatelessWidget {
  const PopupItemWithIconChild({
    super.key,
    required this.icon,
    required this.label,
  });

  final Widget icon;
  final Widget label;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScaleFactorOf(context);
    final double gap =
        scale <= 1 ? 8 : lerpDouble(8, 4, math.min(scale - 1, 1))!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: gap),
        Flexible(
          child: DefaultTextStyle(
            style: context.textTheme.labelLarge ?? const TextStyle(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            child: label,
          ),
        )
      ],
    );
  }
}
