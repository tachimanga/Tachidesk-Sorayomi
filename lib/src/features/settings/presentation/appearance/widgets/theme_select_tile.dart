import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/text_premium.dart';
import '../constants/theme_define.dart';
import '../controller/theme_controller.dart';

class ThemeSelector extends HookConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final key = ref.watch(themeKeyProvider);
    const double height = 45;
    const double width = 68;
    final ThemeData theme = Theme.of(context);
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final schemeKvList = useMemoized(() => ThemeDefine.schemesMap.entries.toList(), []);
    final currentScheme =
        ThemeDefine.schemesMap[key] ?? ThemeDefine.defaultScheme;
    return SizedBox(
      height: 130,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsetsDirectional.only(start: 8, end: 16),
              physics: const ClampingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: schemeKvList.length,
              itemBuilder: (BuildContext context, int index) {
                final pair = schemeKvList[index];
                final themeScheme = pair.value;
                final selected = currentScheme == themeScheme;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          FlexThemeModeOptionButton(
                            flexSchemeColor:
                                isLight ? themeScheme.light : themeScheme.dark,
                            selected: selected,
                            selectedBorder: BorderSide(
                              color: theme.primaryColorLight,
                              width: 2,
                            ),
                            unselectedBorder: BorderSide.none,
                            backgroundColor: scheme.background,
                            width: width,
                            height: height,
                            padding: EdgeInsets.zero,
                            borderRadius: 0,
                            onSelect: () {
                              logEvent2(pipe, "APPEARANCE:THEME:SELECT", {
                                "name": pair.key,
                              });
                              ref
                                  .read(themeKeyProvider.notifier)
                                  .update(pair.key);
                            },
                            optionButtonPadding: EdgeInsets.zero,
                            optionButtonMargin: EdgeInsets.zero,
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            ThemeDefine.toLocale(themeScheme.name, context),
                            style: context.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      if (selected)
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: CircleAvatar(
                              radius: 14,
                              backgroundColor: theme.primaryColorLight,
                              child: Icon(
                                FontAwesomeIcons.check,
                                color: Theme.of(context)
                                    .iconTheme
                                    .color!
                                    .withOpacity(0.7),
                                size: 16,
                              )),
                        ),
                      if (themeScheme != ThemeDefine.defaultScheme) ...[
                        const Positioned(
                          right: 2,
                          top: 1,
                          child: TextPremium(text: ""),
                        )
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
