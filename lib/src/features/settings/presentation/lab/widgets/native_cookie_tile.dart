import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../icons/icomoon_icons.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../browse_center/data/settings_repository/settings_repository.dart';

part 'native_cookie_tile.g.dart';

@riverpod
class NativeCookiePref extends _$NativeCookiePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: "config.javaNativeCookie",
        initial: true,
      );
}

class NativeCookieTile extends HookConsumerWidget {
  const NativeCookieTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(nativeCookiePrefProvider) ?? true;
    final pipe = ref.watch(getMagicPipeProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.switch_left_rounded),
      title: Text("Advanced Cookie Support"),
      subtitle: Text(
        "Added comprehensive Cookie management implementations, including CookieManager, CookieJar and custom Cookie headers.",
        style: context.textTheme.labelSmall
            ?.copyWith(color: Colors.grey, fontSize: 10),
      ),
      contentPadding: kSettingPadding,
      onChanged: (value) async {
        logEvent3("NATIVE:COOKIE:SWITCH:$value");

        // server
        Map<String, bool> map = {'enableNativeCookie': value};
        String json = jsonEncode(map);
        await settingsRepository.uploadSettings(json: json);

        // local
        ref.read(nativeCookiePrefProvider.notifier).update(value);

        // clear cookies
        pipe.invokeMethod("ClearCookies");

        // show tips
        if (!context.mounted) {
          return;
        }
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Text(
                  "If an extension does not work when the switch is turned on, but works normally when the switch is turned off, please report this to @oldmike."),
              actions: [
                PopButton(popText: context.l10n!.ok),
              ],
            );
          },
        );
      },
      value: value,
    );
  }
}
