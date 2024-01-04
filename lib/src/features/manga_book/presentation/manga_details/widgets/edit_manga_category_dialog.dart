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

import '../../../../../constants/app_sizes.dart';

import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/async_buttons/async_checkbox_list_tile.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../library/domain/category/category_model.dart' as model;
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../data/manga_book_repository.dart';
import '../controller/manga_details_controller.dart';

class EditMangaCategoryDialog extends HookConsumerWidget {
  const EditMangaCategoryDialog({
    super.key,
    required this.mangaId,
    this.title,
  });
  final String mangaId;
  final String? title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final provider = mangaCategoryListProvider(mangaId);
    final mangaCategoryList = ref.watch(provider);

    final customCategoryList = categoryList.valueOrNull
        ?.where((e) => e.id != null && e.id != 0)
        .toList();

    final prevKeys = mangaCategoryList.valueOrNull?.keys.toSet() ?? {};

    final selectedCategoryListState = useState(prevKeys);
    useEffect(() {
      selectedCategoryListState.value = prevKeys;
      return;
    }, [mangaCategoryList]);
    final currKeys = selectedCategoryListState.value;

    if (kDebugMode) {
      print("prevKeys $prevKeys");
      print("currKeys $currKeys");
    }
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n!.action_move_category),
          if (title.isNotBlank)
            Text(
              title!,
              style: context.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            )
        ],
      ),
      contentPadding: KEdgeInsets.h8v16.size,
      actions: [
        TextButton(
          onPressed: () {
            context.push(Routes.mangaCategorySetting);
          },
          child: Text(context.l10n!.edit),
        ),
        const PopButton(),
        if (customCategoryList?.isNotEmpty == true) ...[
          TextButton(
            onPressed: () async {
              await AsyncValue.guard(() async {
                await ref.read(mangaBookRepositoryProvider).updateMangaCategory(
                      mangaId,
                      currKeys.toList(),
                    );
              });
              await ref.read(provider.notifier).refresh();
              ref.read(categoryControllerProvider.notifier).reloadCategories();
              if (context.mounted) {
                context.pop();
              }
            },
            child: Text(context.l10n!.ok),
          ),
        ],
      ],
      content: categoryList.showUiWhenData(
        context,
        (__) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: context.height * .7),
            child: customCategoryList.isBlank
                ? Padding(
                    padding: KEdgeInsets.h16.size,
                    child: Text(context.l10n!.noCategoriesFoundAlt),
                  )
                : SingleChildScrollView(
                    child: mangaCategoryList.showUiWhenData(
                      context,
                      (_) => Column(
                        children: [
                          for (model.Category category in customCategoryList!)
                            CheckboxListTile(
                              onChanged: (value) {
                                final keys = selectedCategoryListState.value;
                                if (value == true) {
                                  keys.add("${category.id}");
                                }
                                if (value == false) {
                                  keys.remove("${category.id}");
                                }
                                selectedCategoryListState.value = {...keys};
                              },
                              value: selectedCategoryListState.value.contains(
                                "${category.id}",
                              ),
                              title: Text(category.name ?? ""),
                            ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
