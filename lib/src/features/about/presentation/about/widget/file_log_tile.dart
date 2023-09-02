import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
      title: const Text('Enable log'),
      onChanged: ref.read(fileLogProvider.notifier).update,
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
      title: const Text('Export log'),
      leading: const Icon(Icons.ios_share_rounded),
      onTap: () => pipe.invokeMethod("EXPORT_LOG", ""),
    );
  }
}