// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/pop_button.dart';
import '../../controller/edit_repo_controller.dart';
import '../../domain/repo/repo_model.dart';
import 'widgets/mutil_repo_setting/add_repo_dialog.dart';
import 'widgets/mutil_repo_setting/repo_create_fab.dart';
import 'widgets/mutil_repo_setting/repo_find_button.dart';
import 'widgets/mutil_repo_setting/repo_tile.dart';

class EditRepoScreen extends HookConsumerWidget {
  const EditRepoScreen({
    super.key,
    this.urlSchemeAddRepo,
  });

  final UrlSchemeAddRepo? urlSchemeAddRepo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final magic = ref.watch(getMagicProvider);
    final toast = ref.read(toastProvider(context));
    final repoList = ref.watch(repoControllerProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);

    useEffect(() {
      showImportRepoIfNeeded(context, ref);
      return;
    }, []);

    useEffect(() {
      repoList.showToastOnError(
        ref.read(toastProvider(context)),
        withMicrotask: true,
      );
      return;
    }, [repoList]);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.extension_repo),
        actions: [
          const RepoCreateFab(),
          if (magic.b7 == true) ...[
            IconButton(
              onPressed: () => launchUrlInWeb(
                  context,
                  userDefaults.getString("config.repoHelpUrl") ??
                      AppUrls.repositoriesHelp.url,
                  toast),
              icon: const Icon(Icons.help_rounded),
            ),
          ],
        ],
      ),
      body: repoList.showUiWhenData(
        context,
        (data) {
          if (data.isBlank) {
            return Emoticons(
              text: context.l10n!.empty_repository,
              button: const Column(
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  RepoCreateFab(textButtonStyle: true),
                  RepoFindButton(),
                ],
              ),
            );
          } else {
            return RefreshIndicator(
              child: ListView.builder(
                itemCount: data!.length + 1,
                itemBuilder: (context, index) {
                  if (index == data.length) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: RepoFindButton(),
                    );
                  }
                  final repo = data[index];
                  return RepoTile(
                    key: ValueKey(repo.id),
                    repo: repo,
                  );
                },
              ),
              onRefresh: () => ref.refresh(repoControllerProvider.future),
            );
          }
        },
        refresh: () => ref.refresh(repoControllerProvider.future),
      ),
    );
  }

  void showImportRepoIfNeeded(BuildContext context, WidgetRef ref) {
    https: //stackoverflow.com/questions/74721839/how-do-you-show-a-dialog-snackbar-inside-a-useeffect-on-flutter
    if (urlSchemeAddRepo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AddRepoDialog(
            urlSchemeAddRepo: urlSchemeAddRepo,
          ),
        );
      });
    }
  }
}
