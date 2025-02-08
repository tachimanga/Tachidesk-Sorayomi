// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomPopupMenuWidget extends HookConsumerWidget {
  const CustomPopupMenuWidget({
    super.key,
    required this.popupItems,
    required this.child,
  });

  final List<PopupMenuItem> popupItems;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = useRef<Offset?>(null);
    return GestureDetector(
      onTapDown: (TapDownDetails tapPosition) {
        position.value = tapPosition.globalPosition;
      },
      onLongPress: () {
        if (position.value != null) {
          _showContextMenu(context, position.value!);
        }
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final RenderObject? overlay =
        Overlay.of(context).context.findRenderObject();
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 100, 100),
        Rect.fromLTWH(0, 0, overlay!.paintBounds.size.width,
            overlay.paintBounds.size.height),
      ),
      items: popupItems,
    );
  }
}
