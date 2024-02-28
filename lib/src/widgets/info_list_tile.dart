// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import '../utils/extensions/custom_extensions.dart';

class InfoListTile extends StatelessWidget {
  const InfoListTile({super.key, required this.infoText});

  final String infoText;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        infoText,
        style: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      leading: const Icon(Icons.info_rounded),
      dense: true,
    );
  }
}
