// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const double _singleLineVerticalPadding = 14.0;

class BannerAction {
  const BannerAction({
    required this.text,
    required this.onPress,
  });

  final String text;
  final VoidCallback onPress;
}

class NoticeBanner extends ConsumerWidget {
  const NoticeBanner({
    super.key,
    required this.content,
    this.action,
    this.onClose,
  });

  final Widget content;
  final BannerAction? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final ColorScheme colorScheme = theme.colorScheme;
    final bool isThemeDark = theme.brightness == Brightness.dark;
    final Color buttonColor =
        isThemeDark ? colorScheme.primary : colorScheme.secondary;

    final TextStyle contentTextStyle =
        theme.textTheme.bodyMedium!.copyWith(color: colors.onInverseSurface);

    final bool showCloseIcon = onClose != null;

    const double horizontalPadding = 16.0;
    final EdgeInsetsGeometry padding = EdgeInsetsDirectional.only(
        start: horizontalPadding,
        end: action != null || showCloseIcon ? 0 : horizontalPadding);

    const double actionHorizontalMargin = 2;
    const double iconHorizontalMargin = 2;

    final IconButton? iconButton = showCloseIcon
        ? IconButton(
            icon: const Icon(Icons.close),
            iconSize: 24.0,
            color: colors.onInverseSurface,
            onPressed: () {},
          )
        : null;

    // Calculate combined width of Action, Icon, and their padding, if they are present.
    final TextPainter actionTextPainter = TextPainter(
        text: TextSpan(
          text: action?.text ?? '',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout();
    final double actionAndIconWidth = actionTextPainter.size.width +
        (action != null ? actionHorizontalMargin : 0) +
        (showCloseIcon
            ? (iconButton?.iconSize ?? 0 + iconHorizontalMargin)
            : 0);

    const EdgeInsets margin = EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0);

    final double snackBarWidth =
        MediaQuery.sizeOf(context).width - (margin.left + margin.right);
    const double actionOverflowThreshold = 0.25;

    final bool willOverflowAction =
        actionAndIconWidth / snackBarWidth > actionOverflowThreshold;


    MaterialStateColor resolveForegroundColor() {
      return MaterialStateColor.resolveWith((Set<MaterialState> states) {
        return colors.inversePrimary;
      });
    }

    final List<Widget> maybeActionAndIcon = <Widget>[
      if (action != null)
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: actionHorizontalMargin),
          child: TextButtonTheme(
            data: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: buttonColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: horizontalPadding),
              ),
            ),
            child: TextButton(
              onPressed: action!.onPress,
              style: ButtonStyle(
                foregroundColor: resolveForegroundColor(),
              ),
              child: Text(action!.text),
            ),
          ),
        ),
      if (showCloseIcon)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: iconHorizontalMargin),
          child: iconButton,
        ),
    ];

    Widget snackBar = Padding(
      padding: padding,
      child: Wrap(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: _singleLineVerticalPadding),
                  child: DefaultTextStyle(
                    style: contentTextStyle,
                    child: content,
                  ),
                ),
              ),
              if (!willOverflowAction) ...maybeActionAndIcon,
              if (willOverflowAction) SizedBox(width: snackBarWidth * 0.4),
            ],
          ),
          if (willOverflowAction)
            Padding(
              padding:
                  const EdgeInsets.only(bottom: _singleLineVerticalPadding),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: maybeActionAndIcon),
            ),
        ],
      ),
    );

    snackBar = Material(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
      ),
      elevation: 6.0,
      color: colors.inverseSurface,
      clipBehavior: Clip.hardEdge,
      child: snackBar,
    );

    snackBar = Padding(
      padding: margin,
      child: snackBar,
    );

    return snackBar;
  }
}
