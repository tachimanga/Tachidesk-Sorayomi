// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_constants.dart';
import '../../../../../constants/app_sizes.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/async_buttons/async_text_button.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../domain/update/update_settings_model.dart';
import '../controller/category_settings_controller.dart';

class UpdateSkipTitlesSettingTile extends ConsumerWidget {
  const UpdateSkipTitlesSettingTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restrictionsValue = ref.watch(remoteUpdateRestrictionsProvider);
    final restrictions = restrictionsValue.valueOrNull;
    final list = [
      if (restrictions?.filteredByMangaUnread != false) ...[
        context.l10n!.skip_updating_titles_with_unread_chapters
      ],
      if (restrictions?.filteredByMangaNotStart != false) ...[
        context.l10n!.skip_updating_titles_that_havent_been_read
      ],
      if (restrictions?.filteredByMangaStatus != false) ...[
        context.l10n!.skip_updating_titles_with_completed_status
      ],
    ];
    final subText =
        list.isNotEmpty ? list.join(", ") : context.l10n!.none_label;

    return ListTile(
      title: Text(context.l10n!.skip_updating_titles),
      subtitle: Text(
        subText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall
            ?.copyWith(color: Colors.grey, fontSize: 12),
      ),
      leading: const Icon(Icons.filter_alt),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        logEvent3("UPDATE:SKIP:TILE");
        if (restrictionsValue.isLoading) {
          log("[UPDATE]restrictions isLoading, skip");
          return;
        }
        showDialog(
          context: context,
          builder: (context) => UpdateSkipTitlesSettingDialog(),
        );
      },
    );
  }
}

class UpdateSkipTitlesSettingDialog extends HookConsumerWidget {
  const UpdateSkipTitlesSettingDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final restrictions = ref.watch(remoteUpdateRestrictionsProvider);

    final state = useState(restrictions.valueOrNull ?? UpdateRestrictions());
    useEffect(() {
      state.value = restrictions.valueOrNull ?? UpdateRestrictions();
      return;
    }, [restrictions]);

    return AlertDialog(
      title: Text(context.l10n!.skip_updating_titles),
      contentPadding: KEdgeInsets.h8v16.size,
      content: restrictions.showUiWhenData(
        context,
        (data) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 10.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  context.l10n!.skip_updating_titles_tips,
                  style:
                      context.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: state.value.filteredByMangaUnread != false,
              title:
                  Text(context.l10n!.skip_updating_titles_with_unread_chapters),
              onChanged: (value) {
                state.value =
                    state.value.copyWith(filteredByMangaUnread: value);
              },
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: state.value.filteredByMangaNotStart != false,
              title: Text(
                  context.l10n!.skip_updating_titles_that_havent_been_read),
              onChanged: (value) {
                state.value =
                    state.value.copyWith(filteredByMangaNotStart: value);
              },
            ),
            CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              value: state.value.filteredByMangaStatus != false,
              title: Text(
                  context.l10n!.skip_updating_titles_with_completed_status),
              onChanged: (value) {
                state.value =
                    state.value.copyWith(filteredByMangaStatus: value);
              },
            ),
          ],
        ),
      ),
      actions: [
        PopButton(),
        AsyncTextButton(
          child: Text(context.l10n!.ok),
          onPressed: () async {
            final x = state.value.filteredByMangaUnread != false;
            final y = state.value.filteredByMangaNotStart != false;
            final z = state.value.filteredByMangaStatus != false;
            logEvent3("UPDATE:SKIP:SUBMIT", {
              "x": "$x",
              "y": "$y",
              "z": "$z",
              "url": "$x-$y-$z",
            });
            (await AsyncValue.guard(
              () async {
                await ref
                    .read(remoteUpdateRestrictionsProvider.notifier)
                    .upload(state.value);
                ref.invalidate(remoteUpdateRestrictionsProvider);
                if (context.mounted) {
                  context.pop();
                }
              },
            ))
                .showToastOnError(toast);
          },
        ),
      ],
    );
  }
}
