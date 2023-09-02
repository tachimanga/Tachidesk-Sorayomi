// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/enum.dart';
import '../../../../global_providers/global_providers.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/pop_button.dart';
import '../../data/source_repository/source_repository.dart';
import '../../domain/source_pref/source_pref_model.dart';
import 'controller/source_pref_controller.dart';

class SourcePrefScreen extends HookConsumerWidget {
  const SourcePrefScreen({super.key, required this.sourceId});
  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var sourcePrefProvider = sourcePrefListProvider(sourceId);
    var sourcePref = ref.watch(sourcePrefProvider);

    refresh() => ref.refresh(sourcePrefProvider.future);

    useEffect(() {
      if (!sourcePref.isLoading) refresh();
      return;
    }, []);

    useEffect(() {
      sourcePref.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [sourcePref]);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.settings),
      ),
      body: sourcePref.showUiWhenData(context, (data) =>
          RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
              itemCount: data?.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data?[index].props?.title ?? ""),
                  subtitle: Text(data?[index].props?.summary ?? ""),
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => PrefTextField(
                        sourceId: sourceId,
                        props: data?[index].props,
                        index: index,
                        onSuccess: () => {
                          refresh()
                        }
                    ),
                  ),
                );
              },
            ),
          ),
        refresh: refresh,
      ),
    );
  }
}


class PrefTextField extends HookConsumerWidget {
  const PrefTextField({
    required this.sourceId,
    required this.props,
    required this.index,
    required this.onSuccess,
    super.key,
  });
  final String sourceId;
  final SourcePrefProps? props;
  final int index;
  final VoidCallback onSuccess;

  void _update(String text, WidgetRef ref) {
    AsyncValue.guard(() => ref
        .read(sourceRepositoryProvider)
        .saveSourcePref(sourceId: sourceId, index: index, value: text.trim())
        .then((result) {
          onSuccess();
        }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: props?.currentValue);
    return AlertDialog(
      title: Text(props?.title ?? ""),
      content: TextField(
        autofocus: true,
        controller: controller,
        onSubmitted: (value) {
          _update(controller.text, ref);
          context.pop();
        },
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: (props?.summary ?? ""),
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

