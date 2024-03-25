// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../widgets/highlighted_container.dart';
import '../controller/library_controller.dart';

class LibraryFilterIconButton extends HookConsumerWidget {
  const LibraryFilterIconButton({super.key, required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(libraryMangaFilterUnreadProvider);
    final completed = ref.watch(libraryMangaFilterCompletedProvider);
    final downloaded = ref.watch(libraryMangaFilterDownloadedProvider);

    return HighlightedContainer(
      highlighted: unread != null || completed != null || downloaded != null,
      child: icon,
    );
  }
}
