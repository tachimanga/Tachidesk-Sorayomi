// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../routes/router_config.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../about/presentation/about/controllers/about_controller.dart';
import 'controller/stroage_controller.dart';
import 'domain/storage_model.dart';
import 'widgets/storage_category_tile.dart';
import 'widgets/storage_overview_tile.dart';

class StorageScreen extends ConsumerWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoValue = ref.watch(storageInfoProvider);
    final info = infoValue.valueOrNull;

    final overviewInfoValue = ref.watch(storageOverviewInfoProvider);
    final overviewInfo = overviewInfoValue.valueOrNull;

    final bundleId = ref.watch(packageInfoProvider).packageName;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.storage)),
      body: ListView(
        children: [
          _buildStorageOverview(context, info, overviewInfo),
          _buildOverviewTile(context, ref, info),
          _buildCacheTile(context, ref, info, bundleId),
          _buildLocalSourceTile(context, ref, info),
          _buildDownloadsTile(context, ref, info),
          _buildBackupsTile(context, ref, info),
          _buildOthersTile(context, ref, info),
        ],
      ),
    );
  }

  Widget _buildOverviewTile(
      BuildContext context, WidgetRef ref, StorageInfo? info) {
    return StorageOverviewTile(
      title: context.l10n!.storage_used,
      size: info?.totalSize,
    );
  }

  Widget _buildCacheTile(
      BuildContext context, WidgetRef ref, StorageInfo? info, String bundleId) {
    return StorageCategoryTile(
      title: context.l10n!.storage_cache,
      size: info?.cacheSize,
      subtitle: context.l10n!.storage_cache_subtitle,
      trailing: FilledButton(
        onPressed: (info?.cacheSize ?? 0) > 0
            ? () {
                logEvent3("STORAGE:CACHE:TILE");
                context.push([
                  Routes.settings,
                  Routes.generalSettings,
                  Routes.storageSettings,
                  Routes.storageCacheSettings
                ].toPath);
              }
            : null,
        child: Text(
          context.l10n!.clearCache,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildLocalSourceTile(
      BuildContext context, WidgetRef ref, StorageInfo? info) {
    return StorageCategoryTile(
      title: context.l10n!.local_source,
      size: info?.localSourceSize,
      trailing: OutlinedButton(
        onPressed: (info?.localSourceSize ?? 0) > 0
            ? () {
                logEvent3("STORAGE:LOCALS:TILE");
                context.push([
                  Routes.settings,
                  Routes.generalSettings,
                  Routes.storageSettings,
                  Routes.storageLocalSourcesSettings
                ].toPath);
              }
            : null,
        child: Text(
          context.l10n!.storage_manage_label,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildDownloadsTile(
      BuildContext context, WidgetRef ref, StorageInfo? info) {
    return StorageCategoryTile(
      title: context.l10n!.downloads,
      size: info?.downloadsSize,
      trailing: OutlinedButton(
        onPressed: (info?.downloadsSize ?? 0) > 0
            ? () {
                logEvent3("STORAGE:DOWNLOADS:TILE");
                context.push([
                  Routes.settings,
                  Routes.generalSettings,
                  Routes.storageSettings,
                  Routes.storageDownloadsSettings
                ].toPath);
              }
            : null,
        child: Text(
          context.l10n!.storage_manage_label,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBackupsTile(
      BuildContext context, WidgetRef ref, StorageInfo? info) {
    return StorageCategoryTile(
      title: context.l10n!.backupsSectionTitle,
      size: info?.backupSize,
      trailing: OutlinedButton(
        onPressed: (info?.backupSize ?? 0) > 0
            ? () {
                logEvent3("STORAGE:BACKUP:TILE");
                context.push([
                  Routes.settings,
                  Routes.backup,
                ].toPath);
              }
            : null,
        child: Text(
          context.l10n!.storage_manage_label,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildOthersTile(
      BuildContext context, WidgetRef ref, StorageInfo? info) {
    return StorageCategoryTile(
      title: context.l10n!.storage_other_data,
      subtitle: context.l10n!.storage_other_data_subtitle,
      size: info?.otherSize,
    );
  }

  Widget _buildStorageOverview(
    BuildContext context,
    StorageInfo? appInfo,
    StorageOverviewInfo? overviewInfo,
  ) {
    final appUsage = appInfo?.totalSize ?? 0.0;
    final totalSpace = overviewInfo?.totalCapacity ?? 0.0;
    final freeSpace = overviewInfo?.availableCapacity ?? 0.0;
    final otherAppUsage = totalSpace - appUsage - freeSpace;

    final appPercentage = totalSpace > 0 ? appUsage / totalSpace : 0.0;
    final systemPercentage = totalSpace > 0 ? otherAppUsage / totalSpace : 0.0;
    final freePercentage = totalSpace > 0 ? freeSpace / totalSpace : 100.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStorageBar(
            appPercentage,
            systemPercentage,
            freePercentage,
          ),
          const SizedBox(height: 12),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildStorageBar(
      double appPercent, double systemPercent, double freePercent) {
    return SizedBox(
      height: 10,
      child: Row(
        children: [
          Expanded(
            flex: (appPercent * 1000).round(),
            child: Container(
              color: Colors.green[700],
            ),
          ),
          Expanded(
            flex: (systemPercent * 1000).round(),
            child: Container(
              color: Colors.yellow[700],
            ),
          ),
          Expanded(
            flex: (freePercent * 1000).round(),
            child: Container(
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          context,
          context.l10n!.storage_used,
          Colors.green[700]!,
        ),
        _buildLegendItem(
          context,
          context.l10n!.storage_used_by_other_apps,
          Colors.yellow[700]!,
        ),
        _buildLegendItem(
          context,
          context.l10n!.storage_remaining,
          Colors.grey[300]!,
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
