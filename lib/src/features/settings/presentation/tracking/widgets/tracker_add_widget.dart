import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../data/tracking/tracking_repository.dart';
import '../../../domain/tracking/tracking_model.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/tracking_controller.dart';

class TrackerAddWidget extends ConsumerWidget {
  const TrackerAddWidget(
      {super.key,
      required this.manga,
      required this.tracker,
      required this.refresh});

  final Manga manga;
  final MangaTracker tracker;
  final AsyncCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);
    return ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ServerImage(
            imageUrl: tracker.icon ?? "",
            size: const Size.square(48),
          ),
        ),
        title: Text(context.l10n!.addTracking),
        onTap: () async {
          ref.watch(trackSearchQueryProvider);
          ref.read(trackSearchQueryProvider.notifier).update(manga.title ?? "");
          await context
              .push(Routes.getMangaTrackSearch(tracker.id!, manga.id!));
          await refresh();
          pipe.invokeMethod("LogEvent", "BIND_TRACKER");
        });
  }
}
