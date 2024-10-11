import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';

part 'file_log_tile.g.dart';

@riverpod
class FileLog extends _$FileLog with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.enableFileLog.name,
        initial: DBKeys.enableFileLog.initial,
      );
}

class FileLogTile extends HookConsumerWidget {
  const FileLogTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: const Icon(Icons.switch_left_rounded),
      title: Text(context.l10n!.enableLog),
      contentPadding: kSettingPadding,
      onChanged: (value) {
        ref.read(fileLogProvider.notifier).update(value);
        if (value) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(context.l10n!.log_enable_tips),
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
        }
      },
      value: ref.watch(fileLogProvider).ifNull(),
    );
  }
}

class FileLogExport extends HookConsumerWidget {
  const FileLogExport({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return ListTile(
      title: Text(context.l10n!.exportLog),
      leading: const Icon(Icons.ios_share_rounded),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () => pipe.invokeMethod("EXPORT_LOG", ""),
    );
  }
}
