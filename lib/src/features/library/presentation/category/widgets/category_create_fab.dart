// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../controller/edit_category_controller.dart';
import 'edit_category_dialog.dart';

class CategoryCreateFab extends HookConsumerWidget {
  const CategoryCreateFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final isLoading = useState(false);

    return IconButton(
      onPressed: isLoading.value
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) => EditCategoryDialog(
                  editCategory: (newCategory) async {
                    isLoading.value = true;
                    (await AsyncValue.guard(() async {
                      await ref
                          .read(categoryControllerProvider.notifier)
                          .editCategory(newCategory);
                    }))
                        .showToastOnError(toast);
                    if (context.mounted) {
                      isLoading.value = false;
                    }
                  },
                ),
              );
            },
      icon: isLoading.value
          ? MiniCircularProgressIndicator(color: context.iconColor)
          : const Icon(Icons.add_rounded),
    );
  }
}

class CategoryCreateTextButton extends HookConsumerWidget {
  const CategoryCreateTextButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => EditCategoryDialog(
            editCategory: (newCategory) async {
              (await AsyncValue.guard(() async {
                await ref
                    .read(categoryControllerProvider.notifier)
                    .editCategory(newCategory);
              }))
                  .showToastOnError(toast);
            },
          ),
        );
      },
      icon: const Icon(Icons.add_circle_rounded),
      label: Text(context.l10n!.new_category),
    );
  }
}
