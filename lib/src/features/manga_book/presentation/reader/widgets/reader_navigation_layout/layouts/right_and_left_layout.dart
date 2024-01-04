// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../../../../utils/extensions/custom_extensions.dart';

class RightAndLeftLayout extends StatelessWidget {
  const RightAndLeftLayout({
    super.key,
    this.onLeftTap,
    this.onRightTap,
    this.leftColor,
    this.rightColor,
    this.leftText,
    this.rightText,
    this.menuText,
  });
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;
  final Color? leftColor;
  final Color? rightColor;
  final Widget? leftText;
  final Widget? rightText;
  final Widget? menuText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onLeftTap,
            child: Container(
              color: leftColor,
              child: Center(
                child: leftText,
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox.expand(
            child: Center(
              child: menuText,
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onRightTap,
            child: Container(
              color: rightColor,
              child: Center(
                child: rightText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
