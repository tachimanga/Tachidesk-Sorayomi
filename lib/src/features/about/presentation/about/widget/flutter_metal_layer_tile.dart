import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../icons/icomoon_icons.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'flutter_metal_layer_tile.g.dart';

@riverpod
class FlutterMetalLayerPref extends _$FlutterMetalLayerPref
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: "config.enableFMLOnPhone",
        initial: "1",
      );
}

class FlutterMetalLayerTile extends HookConsumerWidget {
  const FlutterMetalLayerTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(flutterMetalLayerPrefProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.switch_left_rounded),
      title: Text("FlutterMetalLayer"),
      subtitle: Text(
          "If you experience lag on the iPhone, you can enable this option."),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        ref
            .read(flutterMetalLayerPrefProvider.notifier)
            .update(value ? "1" : "0");
        showDialog(
          context: context,
          barrierDismissible: kDebugMode ? true : false,
          builder: (BuildContext context) {
            return AlertDialog(
              content:
                  Text("Changes will take effect after restarting the app."),
              actions: <Widget>[
                ElevatedButton(
                  child: Text(context.l10n!.restartApp),
                  onPressed: () {
                    ref
                        .read(getMagicPipeProvider)
                        .invokeMethod("BACKUP:RESTART");
                    context.pop();
                  },
                ),
              ],
            );
          },
        );
      },
      value: value == "1",
    );
  }
}
