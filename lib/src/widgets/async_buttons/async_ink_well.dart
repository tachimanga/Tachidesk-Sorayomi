// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../custom_circular_progress_indicator.dart';

class AsyncInkWell extends HookWidget {
  const AsyncInkWell({
    super.key,
    this.onTap,
    required this.child,
  });

  final AsyncCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final running = useState(false);
    return InkWell(
      onTap: onTap == null || running.value
          ? null
          : () async {
              running.value = true;
              await onTap!();
              running.value = false;
            },
      child: child,
    );
  }
}
