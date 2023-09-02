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

import '../../../../../../constants/db_keys.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../../widgets/pop_button.dart';

part 'repo_url_tile.g.dart';

@riverpod
class RepoUrl extends _$RepoUrl with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
        ref,
        key: DBKeys.repoUrl.name,
        initial: DBKeys.repoUrl.initial,
      );
}

class RepoUrlTile extends ConsumerWidget {
  const RepoUrlTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoUrl = ref.watch(repoUrlProvider);
    return ListTile(
      leading: const Icon(Icons.computer_rounded),
      title: Text(context.l10n!.externalRepositoryUrl),
      subtitle: repoUrl.isNotBlank ? Text(repoUrl!) : null,
      onTap: () => showDialog(
        context: context,
        builder: (context) => RepoUrlField(initialUrl: repoUrl),
      ),
    );
  }
}

class RepoUrlField extends HookConsumerWidget {
  const RepoUrlField({
    this.initialUrl,
    super.key,
  });
  final String? initialUrl;

  void _update(String url, WidgetRef ref) {
    final tempUrl = url.trim();
    ref.read(repoUrlProvider.notifier).update(tempUrl);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: initialUrl);
    return AlertDialog(
      title: Text(context.l10n!.externalRepositoryUrlShort),
      content: TextField(
        autofocus: true,
        controller: controller,
        onSubmitted: (value) {
          _update(controller.text, ref);
          context.pop();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: context.l10n!.externalRepositoryUrl,
        ),
      ),
      actions: [
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
