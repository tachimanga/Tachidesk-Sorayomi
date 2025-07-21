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
import '../../../../../widgets/invert_checkbox_list_tile.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../library/data/category/category_repository.dart';
import '../../../../library/domain/category/category_model.dart';
import '../../../../library/presentation/category/controller/edit_category_controller.dart';

class UpdateCategoriesSettingTile extends ConsumerWidget {
  const UpdateCategoriesSettingTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final list = [...?categoryList.valueOrNull]
        .where((e) => e.meta?.updateExclude == true)
        .map((e) => e.id == 0 ? context.l10n!.label_default : e.name ?? "")
        .toSet();
    final subText =
        list.isNotEmpty ? list.join(", ") : context.l10n!.none_label;
    return ListTile(
      title: Text(context.l10n!.exclude_categories),
      subtitle: Text(
        subText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.labelSmall
            ?.copyWith(color: Colors.grey, fontSize: 12),
      ),
      leading: const Icon(Icons.block),
      contentPadding: kSettingPadding,
      trailing: kSettingTrailing,
      onTap: () {
        logEvent3("UPDATE:CATEGORY:TILE");
        showDialog(
          context: context,
          builder: (context) => UpdateCategoriesSettingDialog(),
        );
      },
    );
  }
}

class UpdateCategoriesSettingDialog extends HookConsumerWidget {
  const UpdateCategoriesSettingDialog({
    super.key,
  });

  Set<int> _buildExcludeIds(List<Category>? list) {
    return [...?list]
        .where((e) => e.id != null && e.meta?.updateExclude == true)
        .map((e) => e.id!)
        .toSet();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final categoryList = ref.watch(categoryControllerProvider);

    final excludeIds = useState(_buildExcludeIds(categoryList.valueOrNull));
    useEffect(() {
      excludeIds.value = _buildExcludeIds(categoryList.valueOrNull);
      return;
    }, [categoryList]);

    return AlertDialog(
      title: Text(context.l10n!.exclude_categories),
      contentPadding: KEdgeInsets.h8v16.size,
      content: categoryList.showUiWhenData(
        context,
        (data) {
          final list = data?.where((e) => e.id != null).toList();
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.height * .7),
            child: list.isNullOrEmpty
                ? Padding(
                    padding: KEdgeInsets.h16.size,
                    child: Text(context.l10n!.noCategoriesFoundAlt),
                  )
                : SingleChildScrollView(
                    child: Column(
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
                              context.l10n!.exclude_categories_tips,
                              style: context.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ),
                        ),
                        for (final category in list!)
                          InvertCheckboxListTile(
                            title: Text(category.id == 0
                                ? context.l10n!.label_default
                                : category.name ?? ""),
                            value: excludeIds.value.contains(category.id!),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: context.theme.indicatorColor,
                            onChanged: (value) {
                              if (value) {
                                excludeIds.value = {
                                  ...excludeIds.value,
                                  category.id!
                                };
                              } else {
                                excludeIds.value = {...excludeIds.value}
                                  ..remove(category.id!);
                              }
                            },
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
      actions: [
        PopButton(),
        AsyncTextButton(
          enable: categoryList.valueOrNull?.length != excludeIds.value.length,
          onPressed: () async {
            logEvent3("UPDATE:CATEGORY:SUBMIT", {
              "z": "${excludeIds.value.length}/"
                  "${categoryList.valueOrNull?.length}",
            });
            (await AsyncValue.guard(
              () async {
                final dbExcludeIds = _buildExcludeIds(categoryList.valueOrNull);
                final toExcludeIds = excludeIds.value.difference(dbExcludeIds);
                final toIncludeIds = dbExcludeIds.difference(excludeIds.value);

                log("[UPDATE]dbExcludeIds:$dbExcludeIds, "
                    "excludeIds:${excludeIds.value}, "
                    "toExcludeIds:$toExcludeIds, "
                    "toIncludeIds$toIncludeIds");

                for (final id in toExcludeIds) {
                  await ref.read(categoryRepositoryProvider).updateMeta(
                        categoryId: id,
                        key: CategoryMetaKeys.updateExclude.key,
                        value: "true",
                      );
                }
                for (final id in toIncludeIds) {
                  await ref.read(categoryRepositoryProvider).updateMeta(
                        categoryId: id,
                        key: CategoryMetaKeys.updateExclude.key,
                        value: "false",
                      );
                }
                await ref
                    .read(categoryControllerProvider.notifier)
                    .reloadCategories();
                if (context.mounted) {
                  context.pop();
                }
              },
            ))
                .showToastOnError(toast);
          },
          child: Text(context.l10n!.ok),
        ),
      ],
    );
  }
}
