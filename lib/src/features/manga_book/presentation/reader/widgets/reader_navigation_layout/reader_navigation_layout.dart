// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_constants.dart';
import '../../../../../../constants/enum.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../settings/presentation/reader/widgets/reader_invert_tap_tile/reader_invert_tap_tile.dart';
import '../../../../../settings/presentation/reader/widgets/reader_navigation_layout_tile/reader_navigation_layout_tile.dart';
import 'layouts/edge_layout.dart';
import 'layouts/kindlish_layout.dart';
import 'layouts/l_shaped_layout.dart';
import 'layouts/right_and_left_layout.dart';

class ReaderNavigationLayoutWidget extends HookConsumerWidget {
  const ReaderNavigationLayoutWidget({
    super.key,
    required this.navigationLayout,
    required this.readerMode,
    required this.onPrevious,
    required this.onNext,
    this.alwaysShow,
  });
  final ReaderNavigationLayout navigationLayout;
  final ReaderMode readerMode;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool? alwaysShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController =
        useAnimationController(duration: const Duration(seconds: 2));
    useAnimation(animationController);

    final animationFlag = useState(0);
    useEffect(() {
      animationFlag.value = animationFlag.value + 1;
      return;
    }, [navigationLayout]);

    final nextColorTween = alwaysShow == true
        ? Colors.green
        : ColorTween(begin: Colors.green).animate(animationController).value;

    final prevColorTween = alwaysShow == true
        ? Colors.blue
        : ColorTween(begin: Colors.blue).animate(animationController).value;

    final opacityTween = alwaysShow == true
        ? 1.0
        : Tween<double>(begin: 1.0, end: 0.0)
            .animate(animationController)
            .value;

    useEffect(() {
      animationController.reset();
      animationController.forward();
      return;
    }, [animationFlag.value]);

    final invertTap = ref.watch(invertTapProvider).ifNull();
    final VoidCallback? onLeftTap;
    final VoidCallback? onRightTap;
    final Color? leftColor;
    final Color? rightColor;
    final Widget? leftText;
    final Widget? rightText;
    final Widget menuText = Opacity(
      opacity: opacityTween,
      child: Text(
        context.l10n!.tapMenu,
        style: context.textTheme.headlineSmall,
      ),
    );

    final rtl = readerMode == ReaderMode.continuousHorizontalRTL ||
        readerMode == ReaderMode.singleHorizontalRTL;
    final rightAndLeftLayout =
        navigationLayout == ReaderNavigationLayout.rightAndLeft;
    final swap =
        (!rightAndLeftLayout && invertTap) || (rightAndLeftLayout && rtl);

    if (swap) {
      onLeftTap = onNext;
      onRightTap = onPrevious;
      leftColor = nextColorTween;
      rightColor = prevColorTween;
      leftText = Opacity(
        opacity: opacityTween,
        child: Text(
          context.l10n!.nextPage,
          style: context.textTheme.headlineSmall,
        ),
      );
      rightText = Opacity(
        opacity: opacityTween,
        child: Text(
          context.l10n!.prevPage,
          style: context.textTheme.headlineSmall,
        ),
      );
    } else {
      onLeftTap = onPrevious;
      onRightTap = onNext;
      leftColor = prevColorTween;
      rightColor = nextColorTween;
      leftText = Opacity(
        opacity: opacityTween,
        child: Text(
          context.l10n!.prevPage,
          style: context.textTheme.headlineSmall,
        ),
      );
      rightText = Opacity(
        opacity: opacityTween,
        child: Text(
          context.l10n!.nextPage,
          style: context.textTheme.headlineSmall,
        ),
      );
    }

    switch (navigationLayout) {
      case ReaderNavigationLayout.edge:
        return EdgeLayout(
          onLeftTap: onLeftTap,
          onRightTap: onRightTap,
          leftColor: leftColor,
          rightColor: rightColor,
          leftText: leftText,
          rightText: rightText,
          menuText: menuText,
        );
      case ReaderNavigationLayout.kindlish:
        return KindlishLayout(
          onLeftTap: onLeftTap,
          onRightTap: onRightTap,
          leftColor: leftColor,
          rightColor: rightColor,
          leftText: leftText,
          rightText: rightText,
          menuText: menuText,
        );
      case ReaderNavigationLayout.lShaped:
        return LShapedLayout(
          onLeftTap: onLeftTap,
          onRightTap: onRightTap,
          leftColor: leftColor,
          rightColor: rightColor,
          leftText: leftText,
          rightText: rightText,
          menuText: menuText,
        );
      case ReaderNavigationLayout.rightAndLeft:
        return RightAndLeftLayout(
          onLeftTap: onLeftTap,
          onRightTap: onRightTap,
          leftColor: leftColor,
          rightColor: rightColor,
          leftText: Opacity(
            opacity: opacityTween,
            child: Text(
              context.l10n!.leftPage,
              style: context.textTheme.headlineSmall,
            ),
          ),
          rightText: Opacity(
            opacity: opacityTween,
            child: Text(
              context.l10n!.rightPage,
              style: context.textTheme.headlineSmall,
            ),
          ),
          menuText: menuText,
        );
      case ReaderNavigationLayout.disabled:
      case ReaderNavigationLayout.defaultNavigation:
      default:
        return const SizedBox.shrink();
    }
  }
}
