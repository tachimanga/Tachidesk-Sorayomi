// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../library/presentation/category/controller/edit_category_controller.dart';

class EditCategoriesTile extends ConsumerWidget {
  const EditCategoriesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final count = categoryList.valueOrNull?.where((e) => e.id != 0).length ?? 0;
    return ListTile(
      title: Text(context.l10n!.editCategory),
      subtitle: Text(count == 1
          ? context.l10n!.one_category
          : context.l10n!.num_categories(count)),
      leading: const Icon(Icons.label_rounded),
      onTap: () => context.push([
        Routes.settings,
        Routes.librarySettings,
        Routes.editCategories
      ].toPath),
    );
  }
}
