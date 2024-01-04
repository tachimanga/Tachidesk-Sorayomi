// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AsyncIconButton extends HookWidget {
  const AsyncIconButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final AsyncCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final workingState = useState(false);
    return IconButton(
      onPressed: onPressed == null || workingState.value
          ? null
          : () async {
              workingState.value = true;
              await onPressed!();
              workingState.value = false;
            },
      icon: icon,
    );
  }
}
