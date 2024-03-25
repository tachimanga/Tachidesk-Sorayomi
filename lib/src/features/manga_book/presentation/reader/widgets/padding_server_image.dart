// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/reader_setting_controller.dart';

class PaddingServerImage extends ConsumerWidget {
  const PaddingServerImage({
    super.key,
    required this.scrollDirection,
    required this.contextSize,
    required this.mangaId,
    required this.serverImage,
  });

  final Axis scrollDirection;
  final Size contextSize;
  final String mangaId;
  final Widget serverImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orientation = MediaQuery.of(context).orientation;
    //print("orientation image $orientation");
    final portrait = orientation == Orientation.portrait;
    final portraitPadding =
        ref.watch(readerPaddingWithMangaIdProvider(mangaId: mangaId));
    final landscapePadding =
        ref.watch(readerPaddingLandscapeWithMangaIdProvider(mangaId: mangaId));
    final mangaReaderPadding = portrait ? portraitPadding : landscapePadding;

    if (mangaReaderPadding > 0) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: contextSize.height *
              (scrollDirection != Axis.vertical ? mangaReaderPadding : 0),
          horizontal: contextSize.width *
              (scrollDirection == Axis.vertical ? mangaReaderPadding : 0),
        ),
        child: serverImage,
      );
    }

    return serverImage;
  }
}
