// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/navigation_bar_data.dart';
import '../../features/settings/presentation/appearance/controller/theme_controller.dart';
import '../../routes/router_config.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/premium_reset.dart';

class SmallScreenNavigationBar extends ConsumerWidget {
  const SmallScreenNavigationBar({
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
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: MaterialStateProperty.all(
          context.textTheme.labelSmall?.copyWith(overflow: TextOverflow.ellipsis),
        ),
      ),
      child: NavigationBar(
        backgroundColor: dark && pureBlackMode == true ? Colors.black : null,
        selectedIndex: NavigationBarData.indexWherePathOrZero(selectedScreen),
        onDestinationSelected: (value) {
          PremiumReset.instance.resetWhenSwitchTab(selectedScreen, ref);
          final target = NavigationBarData.navList[value].path;
          context.go(target);
          onDestinationSelected(target);
        },
        destinations: NavigationBarData.navList
            .map<NavigationDestination>(
              (e) => NavigationDestination(
                icon: extensionUpdateCount > 0 && e.path == Routes.browse
                    ? Badge(
                        label: Text("$extensionUpdateCount"),
                        offset: badgeOffset,
                        child: Icon(e.icon),
                      )
                    : Icon(e.icon),
                label: e.label(context),
                selectedIcon: Icon(e.activeIcon),
                tooltip: e.label(context),
              ),
            )
            .toList(),
      ),
    );
  }
}
