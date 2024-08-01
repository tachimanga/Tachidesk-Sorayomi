// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../../widgets/text_premium.dart';
import '../../../../custom/inapp/purchase_providers.dart';
import '../controller/app_icon_controller.dart';
import '../model/app_icon_model.dart';

class AppIconSelectTile extends HookConsumerWidget {
  const AppIconSelectTile({super.key});

  static bool appIconSelectTipShow = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final toast = ref.watch(toastProvider(context));

    final appIconKey =
        ref.watch(appIconKeyPrefProvider) ?? DBKeys.appIconKey.initial;
    final appIconMap = ref.watch(appIconMapProvider).valueOrNull ?? {};
    final currentAppIcon =
        appIconMap[appIconKey] ?? AppIconItem(key: kDefaultAppIconKey);

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    return ListTile(
      leading: const Icon(Icons.crop_square),
      title: TextPremium(text: context.l10n!.app_icon_title),
      subtitle: Text(_buildAppIconName(context, currentAppIcon)),
      onTap: () {
        if (appIconMap.isEmpty) {
          return;
        }
        logEvent3("ICON:TAP:TILE");
        showDialog(
          context: context,
          builder: (ctx) => AppIconSelectDialog(
            appIconMap: appIconMap,
            initAppIcon: currentAppIcon,
            onSelect: (appIcon) async {
              ctx.pop();
              final value = appIcon?.key ?? kDefaultAppIconKey;
              (await AsyncValue.guard(
                () async {
                  if (purchaseGate || testflightFlag) {
                    final r = await pipe.invokeMethod("ICON:SET", {
                      "key": value
                    });
                    if (r != null) {
                      logEvent3("ICON:SET:ERROR", {"error": r});
                      throw r;
                    }
                    if (context.mounted) {
                      showTipAlertIfNeeded(context);
                    }
                  }
                  logEvent3("ICON:SET:$value");
                  ref.read(appIconKeyPrefProvider.notifier).update(value);
                },
              ))
                  .showToastOnError(toast);
            },
          ),
        );
      },
    );
  }

  void showTipAlertIfNeeded(BuildContext context) {
    if (appIconSelectTipShow) {
      return;
    }
    appIconSelectTipShow = true;
    _showTipDialog(context);
  }
}

class AppIconSelectDialog extends HookConsumerWidget {
  const AppIconSelectDialog({
    super.key,
    required this.appIconMap,
    required this.initAppIcon,
    required this.onSelect,
  });

  final Map<String, AppIconItem> appIconMap;
  final AppIconItem initAppIcon;
  final ValueChanged<AppIconItem?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      contentPadding: KEdgeInsets.v8.size,
      title: Row(
        children: [
          Text(context.l10n!.app_icon_title),
          IconButton(
            onPressed: () => _showTipDialog(context),
            icon: const Icon(Icons.help_rounded),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: context.height * .6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: appIconMap.values
                .map(
                  (e) => RadioListTile<AppIconItem>(
                    activeColor: context.theme.indicatorColor,
                    contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
                    title: Text(_buildAppIconName(context, e)),
                    subtitle: Text(
                      e.author != null
                          ? context.l10n!.app_icon_author("${e.author}")
                          : "",
                      style: context.textTheme.labelSmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(9.0),
                      child: Image.asset(
                        'assets/icons/${e.key == kDefaultAppIconKey ? 'AppIcon' : e.key}.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                    value: e,
                    groupValue: initAppIcon,
                    onChanged: onSelect,
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: const [
        PopButton(),
      ],
    );
  }
}

String _buildAppIconName(BuildContext context, AppIconItem icon) {
  if (icon.key == kDefaultAppIconKey) {
    return context.l10n!.label_default;
  }
  return icon.name ?? "Untitled";
}

void _showTipDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(context.l10n!.app_icon_update_tip),
      actions: <Widget>[
        ElevatedButton(
          child: Text(context.l10n!.ok),
          onPressed: () {
            ctx.pop();
          },
        ),
      ],
    ),
  );
}