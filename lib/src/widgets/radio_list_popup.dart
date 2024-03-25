// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../utils/extensions/custom_extensions.dart';
import 'pop_button.dart';

class RadioListPopup<T> extends StatelessWidget {
  const RadioListPopup({
    super.key,
    required this.title,
    required this.optionList,
    required this.value,
    required this.onChange,
    this.optionDisplayName,
    this.optionDisplaySubName,
    this.showDisplaySubName,
  });

  final String title;
  final List<T> optionList;
  final T value;
  final ValueChanged<T> onChange;
  final String Function(T)? optionDisplayName;
  final String Function(T)? optionDisplaySubName;
  final bool Function(T)? showDisplaySubName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: KEdgeInsets.v8.size,
      title: Text(title),
      content: RadioList(
        optionList: optionList,
        value: value,
        onChange: onChange,
        displayName: optionDisplayName,
        displaySubName: optionDisplaySubName,
        showDisplaySubName: showDisplaySubName,
      ),
      actions: const [PopButton()],
    );
  }
}

class RadioList<T> extends StatelessWidget {
  const RadioList({
    super.key,
    required this.optionList,
    required this.value,
    required this.onChange,
    this.displayName,
    this.displaySubName,
    this.showDisplaySubName,
  });

  final List<T> optionList;
  final T value;
  final ValueChanged<T> onChange;
  final String Function(T)? displayName;
  final String Function(T)? displaySubName;
  final bool Function(T)? showDisplaySubName;
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: context.height * .7),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: optionList
              .map(
                (e) => RadioListTile<T>(
                  activeColor: context.theme.indicatorColor,
                  title: Text(
                    displayName != null ? displayName!(e) : e.toString(),
                  ),
                  subtitle: (showDisplaySubName != null
                              ? showDisplaySubName!(e)
                              : true) &&
                          displaySubName != null
                      ? Text(displaySubName!(e))
                      : null,
                  value: e,
                  groupValue: value,
                  onChanged: (value) {
                    if (value != null) {
                      onChange(value);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
