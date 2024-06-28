// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../settings/presentation/reader/widgets/reader_double_tap_zoom_in_tile/reader_double_tap_zoom_in_tile.dart';
import '../../../../settings/presentation/reader/widgets/reader_pinch_to_zoom_tile/reader_pinch_to_zoom_tile.dart';
import '../../../data/downloads/downloads_repository.dart';
import '../../../domain/downloads_queue/downloads_queue_model.dart';
import '../../manga_details/controller/manga_details_controller.dart';
import '../controller/ad_controller.dart';
import '../controller/reader_controller.dart';
import '../controller/reader_controller_v2.dart';

var lastTapDownDetails = TapDownDetails();
Animation<Matrix4>? lastAnimation;

class InteractiveWrapper extends HookConsumerWidget {
  const InteractiveWrapper({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.onScaleChanged,
  });

  /// The image to display
  final Widget child;

  /// Minimum scale factor
  final double minScale;

  /// Maximum scale factor
  final double maxScale;

  /// Callback for when the scale has changed, only invoked at the end of
  /// an interaction.
  final void Function(double)? onScaleChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TransformationController transformationController =
        useTransformationController();

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (lastAnimation != null) {
          transformationController.value = lastAnimation!.value;
        }
      });

    final doubleTapZoomIn = ref.watch(readerDoubleTapZoomInProvider);
    final pinchToZoom =
        ref.watch(readerPinchToZoomProvider) ?? DBKeys.pinchToZoom.initial;

    return GestureDetector(
      onDoubleTapDown: doubleTapZoomIn == true ?
          (d) => lastTapDownDetails = d
          : null,
      onDoubleTap: doubleTapZoomIn == true ? () {
        Matrix4 endMatrix;
        Offset position = lastTapDownDetails.localPosition;

        if (transformationController.value != Matrix4.identity()) {
          endMatrix = Matrix4.identity();
          if (onScaleChanged != null) onScaleChanged!(1);
        }
        else {
          const scale = 2.0;
          endMatrix = Matrix4.identity()
            ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
            ..scale(scale);
          if (onScaleChanged != null) onScaleChanged!(scale);
        }
        lastAnimation = Matrix4Tween(
          begin: transformationController.value,
          end: endMatrix,
        ).animate(
          CurveTween(curve: Curves.easeOut).animate(animationController),
        );
        animationController.forward(from: 0);
      } : null,
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: minScale,
        maxScale: maxScale,
        scaleEnabled: pinchToZoom,
        child: child,
        onInteractionEnd: (scaleEndDetails) {
          double scale = transformationController.value.getMaxScaleOnAxis();
          if (onScaleChanged != null) onScaleChanged!(scale);
        },
      ),
    );
  }
}
