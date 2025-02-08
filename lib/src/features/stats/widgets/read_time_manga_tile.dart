// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_nsfw/flutter_nsfw.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/app_sizes.dart';
import '../../../utils/classes/pair/pair_model.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/log.dart';
import '../../../utils/manga_cover_util.dart';
import '../../../widgets/server_image.dart';
import '../../manga_book/domain/manga/manga_model.dart';
import '../../settings/widgets/server_url_tile/server_url_tile.dart';

const kHistoryMangaCoverWidth = 38.0;

final Map<int, Pair<Color, Color>> imageColorCache = {};
final Map<int, double> imageScoreCache = {};

class ReadTimeMangaTile extends ConsumerWidget {
  const ReadTimeMangaTile({
    super.key,
    required this.manga,
    required this.maxReadDuration,
    required this.threshold,
    this.onPressed,
    this.onLongPress,
  });

  final Manga manga;
  final int maxReadDuration;
  final double threshold;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readTimeString = manga.readDuration.toLocalizedReadTime(context);
    const titleFlex = 30;
    const coverFlex = 10;
    const lineFlex = 100 - titleFlex - coverFlex;
    final flex = maxReadDuration != 0
        ? (lineFlex * (manga.readDuration ?? 0)) ~/ maxReadDuration
        : 0;

    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: flex,
              child: SizedBox(
                height: kHistoryMangaCoverWidth,
                child: MangaCoverColorWidget(
                  manga: manga,
                ),
              ),
            ),
            SizedBox(
              width: kHistoryMangaCoverWidth,
              height: kHistoryMangaCoverWidth,
              child: MangaCoverWidget(
                decodeWidth: kMangaCoverDecodeWidth,
                manga: manga,
                threshold: threshold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              // flex: titleFlex,
              flex: 100 - flex - 10,
              child: SizedBox(
                height: kHistoryMangaCoverWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (manga.title ?? context.l10n!.unknownManga),
                      style:
                          context.textTheme.bodyMedium?.copyWith(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (readTimeString != null) ...[
                      Text(
                        readTimeString,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey, fontSize: 10),
                      )
                    ],
                  ],
                ),
              ),
            ),
            // Expanded(
            //   flex: 100 - flex - titleFlex - 10,
            //   child: Container(),
            // ),
          ],
        ),
      ),
    );
  }
}

class MangaCoverWidget extends HookConsumerWidget {
  const MangaCoverWidget({
    super.key,
    required this.manga,
    required this.threshold,
    this.onPressed,
    this.onLongPress,
    this.decodeWidth,
    this.decodeHeight,
  });

  final Manga manga;
  final double threshold;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final int? decodeWidth;
  final int? decodeHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreState = useState<double>(0.0);
    final baseUrl = ref.watch(serverUrlProvider);
    final imageProvider = buildCachedNetworkImageProvider(
      baseUrl: baseUrl,
      imageUrl: manga.thumbnailUrl ?? "",
      imageData: manga.thumbnailImg,
      extInfo: CoverExtInfo.build(manga),
    );
    final resizedImageProvider = ResizeImage.resizeIfNeeded(
      kMangaCoverDecodeWidth,
      kMangaCoverDecodeWidth,
      imageProvider,
    );
    useEffect(() {
      final score = imageScoreCache[manga.id ?? 0];
      if (score != null) {
        if (context.mounted) {
          scoreState.value = score;
        }
        log("[insight]match score cache for id=${manga.id}");
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      getBitmapNSFWScore(resizedImageProvider).then((value) {
        final cost = DateTime.now().millisecondsSinceEpoch - now;
        log("[insight]nsfw score for id=${manga.id} cost:${cost}ms");
        imageScoreCache[manga.id ?? 0] = value ?? 0;
        if (context.mounted) {
          scoreState.value = value ?? 0;
        }
      });
      return;
    }, []);

    return InkResponse(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: manga.thumbnailUrl != null && manga.thumbnailUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ServerImage(
                    imageUrl: manga.thumbnailUrl ?? "",
                    imageData: manga.thumbnailImg,
                    extInfo: CoverExtInfo.build(manga),
                    decodeWidth: decodeWidth,
                    decodeHeight: decodeHeight,
                  ),
                  if (scoreState.value > threshold) ...[
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: kDebugMode
                            ? Text(
                                scoreState.value.toStringAsFixed(2),
                                style: context.textTheme.labelSmall,
                              )
                            : null,
                      ),
                    ),
                  ],
                ],
              )
            : SizedBox(
                height: context.height * .3,
                child: Icon(
                  Icons.book_rounded,
                  color: Colors.grey,
                  size: context.height * .2,
                ),
              ),
      ),
    );
  }

  static Future<double?> getBitmapNSFWScore(
    ImageProvider imageProvider, {
    Size? size,
  }) async {
    final ImageStream stream = imageProvider.resolve(
      ImageConfiguration(size: size, devicePixelRatio: 1.0),
    );
    final Completer<ui.Image> imageCompleter = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      stream.removeListener(listener);
      imageCompleter.complete(info.image);
    });
    stream.addListener(listener);
    final ui.Image image = await imageCompleter.future;
    final ByteData? imageData =
        await image.toByteData(format: ImageByteFormat.png);
    final bytes = imageData?.buffer.asUint8List();
    if (bytes == null) {
      return null;
    }
    return await FlutterNsfw.getBitmapNSFWScore(bytes);
  }
}

class MangaCoverColorWidget extends HookConsumerWidget {
  const MangaCoverColorWidget({
    super.key,
    required this.manga,
  });

  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsState = useState<Pair?>(null);
    final darkMode = context.isDarkMode;

    final baseUrl = ref.watch(serverUrlProvider);
    final imageProvider = buildCachedNetworkImageProvider(
      baseUrl: baseUrl,
      imageUrl: manga.thumbnailUrl ?? "",
      imageData: manga.thumbnailImg,
      extInfo: CoverExtInfo.build(manga),
    );
    final resizedImageProvider = ResizeImage.resizeIfNeeded(
      kMangaCoverDecodeWidth,
      kMangaCoverDecodeWidth,
      imageProvider,
    );
    useEffect(() {
      final colors = imageColorCache[manga.id ?? 0];
      if (colors != null) {
        if (context.mounted) {
          colorsState.value = colors;
        }
        log("[insight]match color cache for id=${manga.id}");
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      PaletteGenerator.fromImageProvider(resizedImageProvider).then((value) {
        final cost = DateTime.now().millisecondsSinceEpoch - now;
        log("[insight]PaletteGenerator for id=${manga.id} cost:${cost}ms");
        final pair = Pair(
          first: value.lightMutedColor?.color.withOpacity(0.6) ?? Colors.grey,
          second: value.dominantColor?.color.withOpacity(0.6) ?? Colors.grey,
        );
        imageColorCache[manga.id ?? 0] = pair;
        if (context.mounted) {
          colorsState.value = pair;
        }
      });
      return;
    }, []);

    return Container(
      color: darkMode ? colorsState.value?.second : colorsState.value?.first,
    );
  }
}
