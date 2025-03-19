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
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/pop_button.dart';
import '../../../../library/domain/category/category_model.dart' as model;
import '../../../../library/presentation/category/controller/edit_category_controller.dart';
import '../../../../manga_book/data/manga_book_repository.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../../manga_book/domain/manga_batch/manga_batch_model.dart';

class BatchEditMangaCategoryDialog extends HookConsumerWidget {
  const BatchEditMangaCategoryDialog({
    super.key,
    required this.mangaList,
    required this.refresh,
  });

  final List<Manga> mangaList;
  final AsyncValueSetter<bool> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryListValue = ref.watch(categoryControllerProvider);
    final categoryList = categoryListValue.valueOrNull;
    final customCategoryList =
        categoryList?.where((e) => e.id != null && e.id != 0).toList();

    final initState = useMemoized(() => _buildInitState());
    final currState = useState(initState);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(context.l10n!.move_manga_to),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(Routes.mangaCategorySetting);
            },
          ),
        ],
      ),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      contentPadding: KEdgeInsets.h16v8.size,
      actionsPadding: const EdgeInsets.fromLTRB(14, 0, 24, 24),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const PopButton(),
            if (customCategoryList?.isNotEmpty == true) ...[
              Flexible(
                child: _buildButton(
                  context,
                  ref,
                  customCategoryList,
                  initState,
                  currState.value,
                ),
              ),
            ],
          ],
        ),
      ],
      content: categoryListValue.showUiWhenData(
        context,
        (__) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: context.height * .7,
              minWidth: 380,
            ),
            child: customCategoryList.isBlank
                ? Padding(
                    padding: KEdgeInsets.h8.size,
                    child: Text(context.l10n!.noCategoriesFoundAlt),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        for (model.Category category in customCategoryList!)
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            title: Text(category.name ?? ""),
                            tristate: currState.value[category.id!] != null
                                ? currState.value[category.id!]!.triState
                                : false,
                            value: currState.value[category.id!] != null
                                ? currState.value[category.id!]!.value
                                : false,
                            onChanged: (value) {
                              final state = {...currState.value};

                              final categoryState = CategoryState(
                                state[category.id!]?.triState ?? false,
                                value,
                              );
                              categoryState.changed = true;
                              state[category.id!] = categoryState;

                              currState.value = state;
                            },
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Map<int, CategoryState> _buildInitState() {
    final categoryIdSet = mangaList
        .where((e) => e.categoryId != null && e.categoryId != 0)
        .map((e) => e.categoryId!)
        .toSet();
    final mangaToCategory = <int, Set<int>>{};
    for (final manga in mangaList) {
      if (manga.id == null || manga.categoryId == null) {
        continue;
      }
      mangaToCategory.putIfAbsent(manga.id!, () => {}).add(manga.categoryId!);
    }

    final Map<int, CategoryState> state = {};
    for (final categoryId in categoryIdSet) {
      var count = 0;
      for (final kv in mangaToCategory.entries) {
        if (kv.value.contains(categoryId)) {
          count++;
        }
      }
      bool triState;
      bool? value;
      if (count == mangaToCategory.length) {
        triState = false;
        value = true;
      } else if (count == 0) {
        triState = false;
        value = false;
      } else {
        triState = true;
        value = null;
      }
      state[categoryId] = CategoryState(triState, value);
    }
    return state;
  }

  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    List<model.Category>? customCategoryList,
    Map<int, CategoryState> initState,
    Map<int, CategoryState> currState,
  ) {
    final toast = ref.read(toastProvider(context));
    return ElevatedButton(
      onPressed: () async {
        (await AsyncValue.guard(
          () async {
            final input = _buildBatchInput(ref, currState);
            if (input.changes?.isNotEmpty == true) {
              await ref
                  .read(mangaBookRepositoryProvider)
                  .mangaBatchUpdate(input: input);
            }
            refresh(true);
            if (context.mounted) {
              context.pop();
            }
          },
        ))
            .showToastOnError(toast);
      },
      child: Text(
        _buildButtonText(
          context,
          ref,
          customCategoryList,
          initState,
          currState,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  MangaBatchInput _buildBatchInput(
    WidgetRef ref,
    Map<int, CategoryState> currState,
  ) {
    final initMangaToCategory = <int, Set<int>>{};
    for (final manga in mangaList) {
      if (manga.id == null || manga.categoryId == null) {
        continue;
      }
      final categoryIds = initMangaToCategory.putIfAbsent(manga.id!, () => {});
      if (manga.categoryId != 0) {
        categoryIds.add(manga.categoryId!);
      }
    }

    List<MangaChange> changes = [];
    for (final kv in initMangaToCategory.entries) {
      final categoryIds = _buildTargetCategoryIds(kv.value, currState);
      if (categoryIds != null) {
        changes.add(MangaChange(mangaId: kv.key, categoryIds: categoryIds));
      }
    }
    return MangaBatchInput(changes: changes);
  }

  List<int>? _buildTargetCategoryIds(
    Set<int> initCategorySet,
    Map<int, CategoryState> currState,
  ) {
    Set<int> ids = {};
    for (final kv in currState.entries) {
      final categoryId = kv.key;
      final state = kv.value;
      if (state.value == true) {
        ids.add(categoryId);
      }
      if (state.value == null && initCategorySet.contains(categoryId)) {
        ids.add(categoryId);
      }
    }
    if (initCategorySet.length == ids.length &&
        initCategorySet.containsAll(ids)) {
      return null;
    }
    return ids.toList();
  }

  String _buildButtonText(
    BuildContext context,
    WidgetRef ref,
    List<model.Category>? customCategoryList,
    Map<int, CategoryState> initState,
    Map<int, CategoryState> currState,
  ) {
    Map<int, String> categoryNameMap = {};
    customCategoryList?.forEach((e) {
      categoryNameMap[e.id ?? 0] = e.name ?? "";
    });

    List<int> keepList = [];
    List<int> removeList = [];
    List<int> addList = [];
    bool allFalse = true;

    for (final kv in currState.entries) {
      final categoryId = kv.key;

      final currValue = kv.value;
      final initValue = initState[categoryId];

      if (currValue.value != false) {
        allFalse = false;
      }

      if (initValue == null) {
        if (currValue.value == true) {
          addList.add(categoryId);
        }
      } else {
        if (initValue.value == currValue.value) {
          keepList.add(categoryId);
        } else if (currValue.value == false) {
          removeList.add(categoryId);
        } else if (currValue.value == true) {
          addList.add(categoryId);
        }
      }
    }

    if (addList.isNotEmpty && removeList.isNotEmpty) {
      final categoryName = categoryNameMap[addList[0]];
      if (addList.length == 1 && categoryName != null) {
        return context.l10n!.move_to_category(categoryName);
      } else {
        return context.l10n!.move_to_categories(addList.length);
      }
    }

    if (allFalse) {
      return initState.isEmpty
          ? context.l10n!.keep_in_default_category
          : context.l10n!.move_to_default_category;
    }

    if (addList.isNotEmpty) {
      final categoryName = categoryNameMap[addList[0]];
      if (addList.length == 1 && categoryName != null) {
        return context.l10n!.add_to_category(categoryName);
      } else {
        return context.l10n!.add_to_categories(addList.length);
      }
    }
    if (removeList.isNotEmpty) {
      final categoryName = categoryNameMap[removeList[0]];
      if (removeList.length == 1 && categoryName != null) {
        return context.l10n!.remove_from_category(categoryName);
      } else {
        return context.l10n!.remove_from_categories(removeList.length);
      }
    }
    if (keepList.isNotEmpty) {
      final categoryName = categoryNameMap[keepList[0]];
      if (keepList.length == 1 && categoryName != null) {
        return context.l10n!.keep_in_category(categoryName);
      } else {
        return context.l10n!.keep_in_categories(keepList.length);
      }
    }
    return context.l10n!.ok;
  }
}

class CategoryState {
  bool triState;
  bool? value;
  bool changed = false;

  CategoryState(
    this.triState,
    this.value,
  );
}
