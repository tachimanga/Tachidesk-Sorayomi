// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/router_config.dart';
import '../utils/extensions/custom_extensions.dart';

class PremiumRequiredTile extends StatelessWidget {
  const PremiumRequiredTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: context.l10n!.premiumRequired,
              style: const TextStyle(color: Colors.red),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: context.l10n!.getPremium,
              style: const TextStyle(color: Colors.blue),
              recognizer: TapGestureRecognizer()
                ..onTap = () => context.push(Routes.purchase),
            ),
          ],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
