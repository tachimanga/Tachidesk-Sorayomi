// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_sizes.dart';
import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/launch_url_in_web.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../controller/edit_repo_controller.dart';
import '../../../../data/repo/repo_repository.dart';
import '../../../../domain/repo/repo_model.dart';

class RepoTile extends HookConsumerWidget {
  const RepoTile({
    super.key,
    required this.repo,
  });

  final Repo repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    return ListTile(
      leading: const Icon(Icons.extension_rounded),
      title: Text(
        repo.name ?? "",
        style: context.textTheme.titleMedium,
      ),
      subtitle: Text(repo.metaUrl ?? ""),
      onTap: () => goToRepoDetail(context),
      trailing: PopupMenuButton(
        shape: RoundedRectangleBorder(
          borderRadius: KBorderRadius.r16.radius,
        ),
        itemBuilder: (context) => [
          if (repo.homePageUrl != null) ...[
            PopupMenuItem(
              child: Text(context.l10n!.homepage_label),
              onTap: () {
                launchUrlInWeb(
                  context,
                  repo.homePageUrl!,
                  toast,
                );
                logEvent3("REPO:TAP:HOMEPAGE", {"x": repo.homePageUrl});
              },
            ),
          ],
          PopupMenuItem(
            child: Text(context.l10n!.label_copy),
            onTap: () {
              final text = "${repo.metaUrl}";
              Clipboard.setData(
                ClipboardData(text: text),
              );
              toast.show(context.l10n!.copyMsg(text),
                  gravity: ToastGravity.TOP);
            },
          ),
          PopupMenuItem(
            child: Text(context.l10n!.delete),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n!.delete_repository),
                content: Text(
                    context.l10n!.delete_repository_content(repo.name ?? "")),
                actions: [
                  const PopButton(),
                  ElevatedButton(
                    onPressed: () async {
                      (await AsyncValue.guard(() async {
                        await ref
                            .read(repoRepositoryProvider)
                            .deleteRepo(repoId: repo.id ?? 0);
                        await ref.refresh(repoControllerProvider.future);
                      }))
                          .showToastOnError(toast);
                      if (context.mounted) {
                        context.pop();
                      }
                    },
                    child: Text(context.l10n!.delete),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void goToRepoDetail(BuildContext context) {
    context.push([
      Routes.settings,
      Routes.browseSettings,
      Routes.editRepo,
      Routes.getRepoDetail(repo.id!, repo.name ?? ""),
    ].toPath);
  }
}
