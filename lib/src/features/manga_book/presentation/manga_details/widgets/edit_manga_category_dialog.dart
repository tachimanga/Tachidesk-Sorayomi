// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../library/domain/category/category_model.dart' as model;
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../data/manga_book_repository.dart';
import '../../../domain/manga/manga_model.dart';
import '../controller/manga_details_controller.dart';

class EditMangaCategoryDialog extends HookConsumerWidget {
  const EditMangaCategoryDialog({
    super.key,
    required this.mangaId,
    this.manga,
  });
  final String mangaId;
  final Manga? manga;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryList = ref.watch(categoryControllerProvider);
    final provider = mangaCategoryListProvider(mangaId);
    final mangaCategoryList = ref.watch(provider);
    final mangaInLibrary = manga?.inLibrary == true;

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

    // if (kDebugMode) {
    //   print("prevKeys $prevKeys");
    //   print("currKeys $currKeys");
    // }
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(mangaInLibrary
              ? context.l10n!.move_manga_to
              : context.l10n!.add_manga_to),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(Routes.mangaCategorySetting);
            },
          ),
        ],
      ),
      contentPadding: KEdgeInsets.h8v16.size,
      actions: [
        const PopButton(),
        if (customCategoryList?.isNotEmpty == true) ...[
          ElevatedButton(
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
            child: Text(_buildButtonText(
              context,
              customCategoryList,
              currKeys,
              mangaInLibrary,
            )),
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

  String _buildButtonText(
    BuildContext context,
    List<model.Category>? customCategoryList,
    Set<String> currKeys,
    bool inLibrary,
  ) {
    String? categoryName = currKeys.length == 1
        ? _findCategoryTitle(customCategoryList, currKeys.first)
        : null;
    if (inLibrary) {
      if (currKeys.isEmpty) {
        return context.l10n!.keep_in_default_category;
      } else {
        if (currKeys.length == 1 && categoryName != null) {
          return context.l10n!.move_to_category(categoryName);
        } else {
          return context.l10n!.move_to_categories(currKeys.length);
        }
      }
    } else {
      if (currKeys.isEmpty) {
        return context.l10n!.add_to_default_category;
      } else {
        if (currKeys.length == 1 && categoryName != null) {
          return context.l10n!.add_to_category(categoryName);
        } else {
          return context.l10n!.add_to_categories(currKeys.length);
        }
      }
    }
  }

  String? _findCategoryTitle(List<model.Category>? list, String categoryId) {
    final category =
        list.firstWhereOrNull((element) => "${element.id}" == categoryId);
    return category?.name;
  }
}

Future<void> refreshMangaAfterEditCategory(
    WidgetRef ref,
    PagingController<int, Manga> controller,
    Manga item,
    int index,
    ) async {
  try {
    final mangaProvider = mangaWithIdProvider(mangaId: "${item.id}");
    await ref.read(mangaProvider.notifier).refresh();
    final mangaValue = ref.read(mangaProvider);
    if (mangaValue.valueOrNull != null) {
      controller.itemList = [...?controller.itemList]
        ..replaceRange(index, index + 1, [mangaValue.valueOrNull!]);
    }
  } catch (e) {
    log("update manga list err:$e");
  }
}