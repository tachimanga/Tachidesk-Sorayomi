// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../controller/useragent_controller.dart';

class UserAgentSelectTile extends HookConsumerWidget {
  const UserAgentSelectTile({
    super.key,
    this.optionList,
  });

  final List<UserAgentTypeEnum>? optionList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    final value = ref.watch(userAgentTypePrefProvider) ??
        UserAgentTypeEnum.defaultWebView;
    final userAgentStrings = ref.watch(userAgentStringsProvider);
    return ListTile(
      leading: const Icon(Icons.public),
      title: Text(context.l10n!.user_agent),
      subtitle: Text(value.toLocale(context)),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<UserAgentTypeEnum>(
          title: context.l10n!.user_agent,
          optionList: optionList ?? UserAgentTypeEnum.values,
          value: value,
          onChange: (value) async {
            logEvent3("USERAGENT:SET:${value.name}");
            await pipe.invokeMethod("USERAGENT:SET", value.index);
            ref.read(userAgentTypePrefProvider.notifier).update(value);
            if (context.mounted) {
              context.pop();
            }
          },
          optionDisplayName: (e) {
            if (e == UserAgentTypeEnum.mobileSafari) {
              return "${e.toLocale(context)} 👍";
            }
            return e.toLocale(context);
          },
          optionDisplaySubName: (e) {
            return userAgentStrings.valueOrNull?[e.index] ?? "";
          },
        ),
      ),
    );
  }
}
