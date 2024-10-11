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
import '../../utils/premium_reset.dart';

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
    const iconSize = 28.0;
    const padding = EdgeInsets.fromLTRB(4, 8, 4, 0);
    return NavigationRail(
      backgroundColor: dark && pureBlackMode == true ? Colors.black : null,
      useIndicator: false,
      elevation: 5,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: kToolbarHeight - 10),
      destinations: NavigationBarData.navList
          .map<NavigationRailDestination>(
            (e) => NavigationRailDestination(
              icon: extensionUpdateCount > 0 && e.path == Routes.browse
                  ? Badge(
                      label: Text("$extensionUpdateCount"),
                      offset: badgeOffset,
                      child: Padding(
                        padding: padding,
                        child: Icon(e.icon, size: iconSize),
                      ),
                    )
                  : Padding(
                      padding: padding,
                      child: Icon(e.icon, size: iconSize),
                    ),
              label: Text(e.label(context)),
              indicatorColor: Colors.transparent,
              selectedIcon: Padding(
                padding: padding,
                child: Icon(e.activeIcon, size: iconSize),
              ),
            ),
          )
          .toList(),
      selectedIndex: NavigationBarData.indexWherePathOrZero(selectedScreen),
      onDestinationSelected: (value) {
        PremiumReset.instance.resetWhenSwitchTab(selectedScreen, ref);
        final target = NavigationBarData.navList[value].path;
        context.go(target);
        onDestinationSelected(target);
      },
    );
  }
}
