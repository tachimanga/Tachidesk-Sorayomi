// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../../../../manga_book/presentation/manga_details/controller/manga_details_controller.dart';
import '../../../data/migrate_repository/migrate_repository.dart';
import '../../../domain/migrate/migrate_model.dart';
import '../controller/migrate_controller.dart';

class MigrateMangaDialog extends HookConsumerWidget {
  const MigrateMangaDialog({
    super.key,
    required this.srcManga,
    required this.destManga,
  });
  final Manga srcManga;
  final Manga destManga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);

    final migrateChapterFlag = ref.watch(migrateChapterPrefProvider);
    final migrateCategoryFlag = ref.watch(migrateCategoryPrefProvider);
    final migrateTrackingFlag = ref.watch(migrateTrackingPrefProvider);

    final migratingState = useState(false);

    if (migratingState.value) {
      return const CenterCircularProgressIndicator();
    }
    return AlertDialog(
      title: Text(context.l10n!.migration_dialog_what_to_include),
      contentPadding: KEdgeInsets.h8v16.size,
      actions: [
        TextButton(
          onPressed: () {
            context.push(Routes.getManga(destManga.id ?? 0));
          },
          child: Text(context.l10n!.migrate_action_show_manga),
        ),
        TextButton(
          onPressed: () async {
            await doMigrate(
                migratingState,
                migrateChapterFlag,
                migrateCategoryFlag,
                migrateTrackingFlag,
                false,
                ref,
                context,
                pipe,
                toast);
          },
          child: Text(context.l10n!.migrate_action_copy),
        ),
        TextButton(
          onPressed: () async {
            await doMigrate(
                migratingState,
                migrateChapterFlag,
                migrateCategoryFlag,
                migrateTrackingFlag,
                true,
                ref,
                context,
                pipe,
                toast);
          },
          child: Text(context.l10n!.migrate_action_migrate),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: migrateChapterFlag,
            title: Text(context.l10n!.chapters),
            onChanged: ref.read(migrateChapterPrefProvider.notifier).update,
          ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: migrateCategoryFlag,
            title: Text(context.l10n!.categories),
            onChanged: ref.read(migrateCategoryPrefProvider.notifier).update,
          ),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: migrateTrackingFlag,
            title: Text(context.l10n!.tracking),
            onChanged: ref.read(migrateTrackingPrefProvider.notifier).update,
          ),
        ],
      ),
    );
  }

  Future<void> doMigrate(
      ValueNotifier<bool> migratingState,
      bool? migrateChapterFlag,
      bool? migrateCategoryFlag,
      bool? migrateTrackingFlag,
      bool replaceFlag,
      WidgetRef ref,
      BuildContext context,
      MethodChannel pipe,
      Toast toast) async {
    pipe.invokeMethod("LogEvent2", <String, Object?>{
      'eventName': 'MIGRATE:EXEC',
      'parameters': <String, String?>{
        'migrateChapterFlag': '$migrateChapterFlag',
        'migrateCategoryFlag': '$migrateCategoryFlag',
        'migrateTrackingFlag': '$migrateTrackingFlag',
        'replaceFlag': '$replaceFlag',
        'srcSourceId': '${srcManga.sourceId}',
        'destSourceId': '${destManga.sourceId}',
      },
    });
    migratingState.value = true;
    (await AsyncValue.guard(() async {
      final param = MigrateRequest(
        srcMangaId: srcManga.id!,
        destMangaId: destManga.id!,
        migrateChapterFlag: migrateChapterFlag,
        migrateCategoryFlag: migrateCategoryFlag,
        migrateTrackFlag: migrateTrackingFlag,
        replaceFlag: replaceFlag,
      );
      await ref.read(migrateRepositoryProvider).doMigrate(param: param);
      if (replaceFlag) {
        ref.invalidate(
            migrateMangaListProvider(sourceId: srcManga.sourceId ?? ""));
        ref.invalidate(mangaWithIdProvider(mangaId: "${srcManga.id}"));
      }
      ref.invalidate(migrateSourceListProvider);
      if (context.mounted) {
        context.pop();
        context.pushReplacement(Routes.getManga(destManga.id ?? 0));
      }
    }))
        .showToastOnError(toast);
    migratingState.value = false;
  }
}
