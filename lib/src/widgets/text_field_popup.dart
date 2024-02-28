// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_sizes.dart';
import '../utils/extensions/custom_extensions.dart';
import 'pop_button.dart';

class TextFieldPopup extends HookWidget {
  const TextFieldPopup({
    super.key,
    required this.title,
    required this.onChange,
    this.subtitle,
    this.hint,
    this.initialValue,
    this.textInputAction,
  });

  final String title;
  final String? subtitle;
  final String? hint;
  final String? initialValue;
  final ValueChanged<String> onChange;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController(text: initialValue);
    return AlertDialog(
      contentPadding: KEdgeInsets.a16.size,
      title: Text(title),
      content: Padding(
        padding: KEdgeInsets.h8.size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotBlank)
              Padding(
                padding: KEdgeInsets.v4.size,
                child: Text(subtitle!),
              ),
            Padding(
              padding: KEdgeInsets.v16.size,
              child: TextField(
                autofocus: true,
                onSubmitted: (value) {
                  onChange(value);
                  context.pop();
                },
                controller: textEditingController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: hint ?? "",
                ),
                textInputAction: textInputAction,
                maxLines: textInputAction == TextInputAction.newline ? null : 1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        const PopButton(),
        ElevatedButton(
          onPressed: () {
            onChange(textEditingController.text);
          },
          child: Text(context.l10n!.save),
        )
      ],
    );
  }
}
