import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../widgets/slider_setting_tile/slider_setting_tile.dart';
import '../controller/theme_controller.dart';

class BlendLevelSlider extends ConsumerWidget {
  const BlendLevelSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliderSettingTile(
      defaultValue: DBKeys.themeBlendLevel.initial,
      labelGenerator: (value) => value.round().toString(),
      title: context.l10n!.themeColorBlendLevel,
      icon: Icons.layers_rounded,
      value:
      ref.watch(themeBlendLevelProvider) ?? DBKeys.themeBlendLevel.initial,
      onChanged: (val) =>
          ref.read(themeBlendLevelProvider.notifier).update(val.roundToDouble()),
      min: 0.0,
      max: 40.0,
    );
  }
}
