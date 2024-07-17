// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../data/manga_book_repository.dart';
import '../../domain/chapter_patch/chapter_put_model.dart';

class SingleChapterActionIcon extends ConsumerWidget {
  const SingleChapterActionIcon({
    this.icon,
    this.imageIcon,
    required this.chapterPut,
    required this.refresh,
    super.key,
  }) : assert(imageIcon != null || icon != null);
  final ChapterModifyInput chapterPut;
  final AsyncCallback refresh;
  final IconData? icon;
  final ImageIcon? imageIcon;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    return IconButton(
      icon: imageIcon ?? Icon(icon),
      onPressed: () async {
        (await AsyncValue.guard(
          () => ref.read(mangaBookRepositoryProvider).chapterModify(
                input: chapterPut,
              ),
        ))
            .showToastOnError(toast);
        await refresh();
      },
    );
  }
}
