// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/classes/trace/trace_model.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';

class ImgError extends HookConsumerWidget {
  const ImgError({
    super.key,
    this.text,
    this.button,
    this.traceInfo,
    this.imageUrl,
  });
  final String? text;
  final Widget? button;
  final TraceInfo? traceInfo;
  final String? imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    useEffect(() {
      final parts = text?.split(", uri = ");
      logEvent2(pipe, "IMAGE_LOAD_ERROR", {
        "type": traceInfo?.type,
        "sourceId": traceInfo?.sourceId,
        "x": traceInfo?.mangaUrl,
        "url": imageUrl,
        "error": parts.firstOrNull,
      });
      return;
    }, []);
    return Padding(
      padding: KEdgeInsets.a8.size,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              color: Colors.grey,
            ),
            KSizedBox.h32.size,
            if (text.isNotBlank)
              Text(
                text!,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            if (button != null) button!,
          ],
        ),
      ),
    );
  }
}
