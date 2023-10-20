// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';

class PageNumberSlider extends StatelessWidget {
  const PageNumberSlider({
    super.key,
    required this.currentValue,
    required this.maxValue,
    required this.onChanged,
    this.reverse = false,
  });
  final int currentValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: reverse == false
              ? [
                  Text("${currentValue + 1}"),
                  Expanded(
                    child: Slider(
                      value:
                          min(currentValue.toDouble(), maxValue.toDouble() - 1),
                      min: 0,
                      max: maxValue.toDouble() - 1,
                      divisions: max(maxValue - 1, 1),
                      onChanged: (val) => onChanged(val.toInt()),
                    ),
                  ),
                  Text("$maxValue"),
                ]
              : [
                  Text("$maxValue"),
                  Expanded(
                    child: Slider(
                      value: min(maxValue - 1 - currentValue.toDouble(),
                          maxValue.toDouble() - 1),
                      min: 0,
                      max: maxValue.toDouble() - 1,
                      divisions: max(maxValue - 1, 1),
                      onChanged: (val) =>
                          onChanged((maxValue - 1 - val).toInt()),
                    ),
                  ),
                  Text("${currentValue + 1}"),
                ],
        ),
      ),
    );
  }
}
