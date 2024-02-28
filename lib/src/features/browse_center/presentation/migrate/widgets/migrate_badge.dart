// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../../constants/app_sizes.dart';

class MigrateBadge extends StatelessWidget {
  const MigrateBadge({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
  });
  final String text;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: KBorderRadius.r8.radius,
      child: Card(
        margin: EdgeInsets.zero,
        color: color,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          child: Text(text, style: TextStyle(color: textColor)),
        ),
      ),
    );
  }
}
