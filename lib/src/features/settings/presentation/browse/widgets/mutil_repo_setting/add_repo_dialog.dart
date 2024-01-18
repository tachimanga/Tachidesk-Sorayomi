// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../../browse_center/presentation/extension/controller/extension_controller.dart';
import '../../../../controller/edit_repo_controller.dart';
import '../../../../data/repo/repo_repository.dart';
import '../../../../domain/repo/repo_model.dart';
import '../repo_setting/repo_url_tile.dart';

class AddRepoDialog extends HookConsumerWidget {
  const AddRepoDialog({
    super.key,
    this.urlSchemeAddRepo,
  });

  final UrlSchemeAddRepo? urlSchemeAddRepo;

  Future<void> submitAddRepo(
    String? repoName,
    String? metaUrl,
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> addingState,
  ) async {
    log("submitAddRepo repoName:$repoName, metaUrl:$metaUrl");
    if (repoName != null) {
      repoName = repoName.trim();
    }
    if (metaUrl != null) {
      metaUrl = metaUrl.trim();
    }
    if (!(repoName?.isNotBlank == true || metaUrl?.isNotBlank == true)) {
      return;
    }
    if (metaUrl == null &&
        repoName?.startsWith("http") == true &&
        repoName?.endsWith("index.min.json") == true) {
      metaUrl = repoName;
      repoName = null;
    }
    if (repoName?.startsWith("https://github.com/") == true) {
      repoName = repoName?.replaceAll("https://github.com/", "");
    }
    if (metaUrl?.startsWith("http") == true && metaUrl?.endsWith("/") == true) {
      metaUrl = "${metaUrl}index.min.json";
    }

    FocusManager.instance.primaryFocus?.unfocus();
    final toast = ref.read(toastProvider(context));
    final param = AddRepoParam(repoName: repoName, metaUrl: metaUrl);
    log("submitAddRepo param:${param.toJson()}");
    addingState.value = true;
    Repo? repo;
    final failTipText = context.l10n!.get_repo_meta_fail;
    (await AsyncValue.guard(() async {
      try {
        await ref.read(repoRepositoryProvider).checkRepo(param: param);
      } catch (e) {
        throw Exception('$failTipText\n${e.toString()}');
      }
      repo = await ref.read(repoRepositoryProvider).createRepo(param: param);
      await ref.refresh(repoControllerProvider.future);
      await ref.refresh(extensionProvider.future);
      if (context.mounted) {
        context.pop();
      }
    }))
        .showToastOnError(toast);
    addingState.value = false;

    ref.read(repoUrlProvider.notifier).update(repo?.baseUrl ?? "");

    if (repo != null) {
      if (context.mounted) {
        context.push([
          Routes.settings,
          Routes.browseSettings,
          Routes.editRepo,
          Routes.getRepoDetail(repo!.id!, repo?.name ?? ""),
        ].toPath);
      }
    }

    // log
    pipe.invokeMethod("LogEvent2", <String, Object?>{
      'eventName': repo != null ? 'REPO:ADD:SUCC' : 'REPO:ADD:FAIL',
      'parameters': <String, String?>{
        'repoName': param.repoName,
        'metaUrl': param.metaUrl,
      },
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byName = useState(true);
    final repoName = useTextEditingController();
    final repoMetaUrl = useTextEditingController();
    final addingState = useState(false);
    final repoNameEmpty = useState(false);
    final repoMetaUrlEmpty = useState(false);

    if (urlSchemeAddRepo != null) {
      final name = urlSchemeAddRepo?.repoName?.isNotEmpty == true
          ? "${urlSchemeAddRepo?.repoName}\n"
          : "";
      final url = urlSchemeAddRepo?.baseUrl?.isNotEmpty == true
          ? "${urlSchemeAddRepo?.baseUrl}index.min.json"
          : urlSchemeAddRepo?.metaUrl;
      return AlertDialog(
        title: Row(
          children: [
            Text(context.l10n!.add_repository),
            if (addingState.value) ...[const MiniCircularProgressIndicator()],
          ],
        ),
        content: Text("$name$url"),
        actions: [
          const PopButton(),
          ElevatedButton(
            onPressed: addingState.value
                ? null
                : () {
                    submitAddRepo(null, url, context, ref, addingState);
                  },
            child: Text(addingState.value
                ? context.l10n!.label_adding
                : context.l10n!.label_add),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Text(context.l10n!.add_repository),
          if (addingState.value) ...[const MiniCircularProgressIndicator()],
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(byName.value
              ? context.l10n!.add_repo_by_name_tip
              : context.l10n!.add_repo_by_url_tip),
          const SizedBox(
            height: 20,
          ),
          byName.value
              ? TextField(
                  controller: repoName,
                  autofocus: true,
                  enabled: !addingState.value,
                  decoration: InputDecoration(
                    hintText: "username/repo",
                    errorText: repoNameEmpty.value ? "" : null,
                    border: const OutlineInputBorder(),
                  ),
                )
              : TextField(
                  controller: repoMetaUrl,
                  autofocus: true,
                  enabled: !addingState.value,
                  decoration: InputDecoration(
                    hintText: "https://example.com/repo/index.min.json",
                    errorText: repoMetaUrlEmpty.value ? "" : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: true,
                    visualDensity: VisualDensity.compact,
                    groupValue: byName.value,
                    onChanged: (value) {
                      if (value == true) {
                        byName.value = true;
                      }
                    },
                  ),
                  Text(context.l10n!.add_repo_by_name)
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    value: false,
                    visualDensity: VisualDensity.compact,
                    groupValue: byName.value,
                    onChanged: (value) {
                      if (value == false) {
                        byName.value = false;
                      }
                    },
                  ),
                  Text(context.l10n!.add_repo_by_url)
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        const PopButton(),
        ElevatedButton(
          onPressed: addingState.value
              ? null
              : () {
                  if (byName.value) {
                    repoNameEmpty.value = repoName.text.isBlank;
                    submitAddRepo(
                        repoName.text, null, context, ref, addingState);
                  } else {
                    repoMetaUrlEmpty.value = repoMetaUrl.text.isBlank;
                    submitAddRepo(
                        null, repoMetaUrl.text, context, ref, addingState);
                  }
                },
          child: Text(addingState.value
              ? context.l10n!.label_adding
              : context.l10n!.label_add),
        ),
      ],
    );
  }
}
