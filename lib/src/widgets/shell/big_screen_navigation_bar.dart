// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/gen/assets.gen.dart';
import '../../constants/navigation_bar_data.dart';
import '../../features/settings/presentation/appearance/controller/theme_controller.dart';
import '../../routes/router_config.dart';
import '../../utils/extensions/custom_extensions.dart';

class BigScreenNavigationBar extends ConsumerWidget {
  const BigScreenNavigationBar({
    super.key,
    required this.selectedScreen,
    required this.onDestinationSelected,
    required this.extensionUpdateCount,
  });

  final String selectedScreen;
  final ValueChanged<String> onDestinationSelected;
  final int extensionUpdateCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Offset badgeOffset = Directionality.of(context) == TextDirection.ltr
        ? const Offset(12, -4)
        : const Offset(-12, -4);
    final pureBlackMode = ref.watch(themePureBlackProvider);
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return NavigationRail(
      backgroundColor: dark && pureBlackMode == true ? Colors.black : null,
      useIndicator: true,
      elevation: 5,
      extended: context.isDesktop,
      labelType: context.isDesktop
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      leading: context.isDesktop
          ? TextButton.icon(
              onPressed: () => {},
              icon: ImageIcon(
                AssetImage(Assets.icons.darkIcon.path),
                size: 48,
              ),
              label: Text(context.l10n!.appTitle),
              style: TextButton.styleFrom(
                foregroundColor: context.textTheme.bodyLarge?.color,
              ),
            )
          : IconButton(
              onPressed: () => {},
              icon: ImageIcon(
                AssetImage(Assets.icons.darkIcon.path),
                size: 48,
              ),
            ),
      destinations: NavigationBarData.navList
          .map<NavigationRailDestination>(
            (e) => NavigationRailDestination(
              icon: extensionUpdateCount > 0 && e.path == Routes.browse
                  ? Badge(
                      label: Text("$extensionUpdateCount"),
                      offset: badgeOffset,
                      child: Icon(e.icon),
                    )
                  : Icon(e.icon),
              label: Text(e.label(context)),
              selectedIcon: Icon(e.activeIcon),
            ),
          )
          .toList(),
      selectedIndex: NavigationBarData.indexWherePathOrZero(selectedScreen),
      onDestinationSelected: (value) {
        final target = NavigationBarData.navList[value].path;
        context.go(target);
        onDestinationSelected(target);
      },
    );
  }
}
