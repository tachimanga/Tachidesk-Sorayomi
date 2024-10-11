// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../../browse_center/presentation/extension/controller/extension_controller.dart';
import '../../../../controller/edit_repo_controller.dart';
import '../../../../controller/remote_blacklist_controller.dart';
import '../../../../data/config/remote_blacklist_config.dart';
import '../../../../data/repo/repo_repository.dart';
import '../../../../domain/repo/repo_model.dart';
import '../repo_setting/repo_url_tile.dart';
import 'add_repo_agreement_dialog.dart';

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
    final parts = context.l10n!.extension_usage_terms.split("\n");
    //print("[DEBUG]parts $parts");
    if (parts.length != 4) {
      doSubmitAddRepo(repoName, metaUrl, context, ref, addingState);
      return;
    }
    showDialog(
      context: context,
      builder: (innerCtx) => AddRepoDialogAgreementDialog(
        parts: parts,
        onAgreed: () {
          innerCtx.pop();
          doSubmitAddRepo(repoName, metaUrl, context, ref, addingState);
        },
      ),
    );
  }

  Future<void> doSubmitAddRepo(
    String? repoName,
    String? metaUrl,
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> addingState,
  ) async {
    log("[REPO]submitAddRepo repoName:$repoName, metaUrl:$metaUrl");
    final userDefaults = ref.read(sharedPreferencesProvider);
    if (repoName != null) {
      repoName = repoName.trim();
    }
    if (metaUrl != null) {
      metaUrl = metaUrl.trim();
    }
    if (!(repoName?.isNotBlank == true || metaUrl?.isNotBlank == true)) {
      return;
    }
    final logRepoName = repoName;
    final logMetaUrl = metaUrl;

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
    final blacklist = ref.read(blacklistConfigProvider);
    final param = AddRepoParam(repoName: repoName, metaUrl: metaUrl);
    log("[REPO]submitAddRepo param:${param.toJson()}");
    addingState.value = true;
    Repo? repo;
    final failTipText = context.l10n!.get_repo_meta_fail;
    final repoNotExistText = context.l10n!.repo_not_exist;
    (await AsyncValue.guard(() async {
      _checkBlacklist(param, blacklist, failTipText);
      try {
        await ref.read(repoRepositoryProvider).checkRepo(param: param);
      } catch (e) {
        var detail = e.toString();
        if (detail.startsWith("HTTP error 4")) {
          detail = repoNotExistText;
        }
        throw Exception('$failTipText\n$detail');
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

    if (repo?.baseUrl.isNotBlank == true) {
      ref.read(repoUrlProvider.notifier).update(repo?.baseUrl ?? "");
    }

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
        'x': logRepoName,
        'y': logMetaUrl,
      },
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoName = useTextEditingController();
    final repoMetaUrl = useTextEditingController();
    final addingState = useState(false);
    final repoNameEmpty = useState(false);
    final repoMetaUrlEmpty = useState(false);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final byUrlFirst = userDefaults.getString("config.byUrlFirst") == "1";
    final byUrlOnly = userDefaults.getString("config.byUrlOnly") == "1";
    final byName = useState(!byUrlFirst);
    log("[REPO]byUrlFirst $byUrlFirst");

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
                    hintStyle: context.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    errorText: repoMetaUrlEmpty.value ? "" : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
          if (!byUrlFirst) ...[
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
          if (byUrlFirst && !byUrlOnly) ...[
            Row(
              children: [
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
                const SizedBox(
                  width: 10,
                ),
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
              ],
            ),
          ],
        ],
      ),
      actions: [
        const PopButton(),
        ElevatedButton(
          onPressed: addingState.value
              ? null
              : () {
                  if (byName.value) {
                    final blank = repoName.text.isBlank;
                    repoNameEmpty.value = blank;
                    if (!blank) {
                      submitAddRepo(
                          repoName.text, null, context, ref, addingState);
                    }
                  } else {
                    final blank = repoMetaUrl.text.isBlank;
                    repoMetaUrlEmpty.value = blank;
                    if (!blank) {
                      submitAddRepo(
                          null, repoMetaUrl.text, context, ref, addingState);
                    }
                  }
                },
          child: Text(addingState.value
              ? context.l10n!.label_adding
              : context.l10n!.label_add),
        ),
      ],
    );
  }

  void _checkBlacklist(
    AddRepoParam param,
    BlacklistConfig blacklistConfig,
    String commonErrStr,
  ) {
    if (blacklistConfig.blackRepoUrlList?.isNotEmpty == true) {
      if (param.repoName != null) {
        final name = param.repoName;
        final black = blacklistConfig.blackRepoUrlList?.contains(name) == true;
        log('[REPO]repo name:$name, black:$black');
        if (black) {
          logEvent3("BLACK:REPO:NAME", {"x": name});
          throw commonErrStr;
        }
      }
      if (param.metaUrl != null) {
        final url = param.metaUrl;
        final black = blacklistConfig.blackRepoUrlList?.contains(url) == true;
        log('[REPO]repo metaUrl:$url, black:$black');
        if (black) {
          logEvent3("BLACK:REPO:URL", {"x": url});
          throw commonErrStr;
        }
      }
    }
  }
}
