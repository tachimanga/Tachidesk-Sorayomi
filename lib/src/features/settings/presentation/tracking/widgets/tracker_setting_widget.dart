import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../constants/enum.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../../manga_book/presentation/manga_details/controller/manga_details_controller.dart';
import '../../../data/tracking/tracking_repository.dart';
import '../../../domain/tracking/tracking_model.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/tracking_controller.dart';
import 'tracker_add_widget.dart';
import 'tracker_status_widget.dart';

class TrackerSettingWidget extends ConsumerWidget {
  const TrackerSettingWidget(
      {super.key, required this.mangaId, required this.refresh});

  final String mangaId;
  final AsyncCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeAreaBottom = MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.bottom;
    final mangaWithId = ref.watch(mangaWithIdProvider(mangaId: mangaId));
    return mangaWithId.showUiWhenData(context, (data) {
      final manga = data!;
      final trackers = manga.trackers!;
      return Padding(
        padding: EdgeInsets.fromLTRB(5, 5, 5, safeAreaBottom),
        child: ListView.separated(
          padding: const EdgeInsets.all(0),
          itemCount: trackers.length,
          primary: false,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final tracker = trackers[index];
            if (tracker.record == null) {
              return TrackerAddWidget(
                  manga: manga, tracker: tracker, refresh: refresh);
            } else {
              return TrackerStatusWidget(
                  manga: manga, tracker: tracker, refresh: refresh);
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      );
    });
  }
}
