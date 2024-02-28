// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../constants/db_keys.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../widgets/pop_button.dart';

part 'server_url_tile.g.dart';

@riverpod
class ServerUrl extends _$ServerUrl with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: DBKeys.serverUrl.name,
        initial: DBKeys.serverUrl.initial,
      );
}

class ServerUrlTile extends ConsumerWidget {
  const ServerUrlTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverUrl = ref.watch(serverUrlProvider);
    return ListTile(
      leading: const Icon(Icons.computer_rounded),
      title: Text(context.l10n!.serverUrl),
      subtitle: serverUrl.isNotBlank ? Text(serverUrl!) : null,
      onTap: () => showDialog(
        context: context,
        builder: (context) => ServerUrlField(initialUrl: serverUrl),
      ),
    );
  }
}

class ServerUrlField extends HookConsumerWidget {
  const ServerUrlField({
    this.initialUrl,
    super.key,
  });
  final String? initialUrl;

  void _update(String url, WidgetRef ref) {
    final tempUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    ref.read(serverUrlProvider.notifier).update(tempUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: initialUrl);
    return AlertDialog(
      title: Text(context.l10n!.serverUrl),
      content: TextField(
        autofocus: true,
        controller: controller,
        onSubmitted: (value) {
          _update(controller.text, ref);
          context.pop();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: (context.l10n!.serverUrlHintText),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            _update("http://127.0.0.1:4567", ref);
            context.pop();
          },
          child: Text("local"),
        ),
        ElevatedButton(
          onPressed: () {
            _update("http://192.168.0.42:4567", ref);
            context.pop();
          },
          child: Text("server"),
        ),
        const PopButton(),
        ElevatedButton(
          onPressed: () {
            _update(controller.text, ref);
            context.pop();
          },
          child: Text(context.l10n!.save),
        ),
      ],
    );
  }
}
