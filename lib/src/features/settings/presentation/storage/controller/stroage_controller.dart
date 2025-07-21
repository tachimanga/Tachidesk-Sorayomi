import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../about/presentation/about/controllers/about_controller.dart';
import '../../../../browse_center/data/source_repository/source_repository.dart';
import '../../../../browse_center/domain/source/source_model.dart';
import '../../../../manga_book/data/downloads/downloads_repository.dart';
import '../../../../manga_book/domain/manga/manga_model.dart';
import '../domain/storage_model.dart';
import '../utils/storage_util.dart';

part 'stroage_controller.g.dart';

class StorageAction {
  const StorageAction(this.pipe);
  final MethodChannel pipe;

  Future<void> clearCacheDirs(List<String> dirs) async {
    final str = await pipe.invokeMethod("STORAGE:CLEAN:DIRS", dirs);
    if (str != "OK") {
      throw str;
    }
  }

  Future<void> clearCacheWebKit() async {
    final str = await pipe.invokeMethod("STORAGE:CLEAN:WEBKIT");
    if (str != "OK") {
      throw str;
    }
  }

  Future<void> clearCacheNSCache() async {
    final str = await pipe.invokeMethod("STORAGE:CLEAN:NSCACHE");
    if (str != "OK") {
      throw str;
    }
  }

  Future<void> deleteFilesAtPaths(List<String> paths) async {
    final str = await pipe.invokeMethod("STORAGE:CLEAN:PATHS", paths);
    if (str != "OK") {
      throw str;
    }
  }
}

@riverpod
StorageAction storageAction(Ref ref) =>
    StorageAction(ref.watch(getMagicPipeProvider));

@riverpod
Future<StorageRawInfo?> storageRawInfo(Ref ref) async {
  final pipe = ref.watch(getMagicPipeProvider);
  final str = await pipe.invokeMethod("STORAGE:QUERY");
  //await Future.delayed(Duration(seconds: 10));
  return StorageRawInfo.fromJson(json.decode(str));
}

@riverpod
Future<StorageOverviewInfo?> storageOverviewInfo(Ref ref) async {
  final pipe = ref.watch(getMagicPipeProvider);
  final str = await pipe.invokeMethod("STORAGE:OVERVIEW:QUERY");
  final info = StorageOverviewInfo.fromJson(json.decode(str));
  return info;
}

@riverpod
Future<StorageInfo?> storageInfo(Ref ref) async {
  final rawInfoValue = ref.watch(storageRawInfoProvider);
  final bundleId = ref.watch(packageInfoProvider).packageName;
  final rawInfo = rawInfoValue.valueOrNull;

  final totalSize = rawInfo?.size;

  final imageCacheSize = batchFetchStorageSize(rawInfo, [
    "/Library/Caches/libCachedImageData",
    "/Library/Application Support/Tachidesk/thumbnails",
    "/Library/Application Support/Tachidesk/manga-cache",
  ]);

  final coverCacheSize = fetchStorageSize(
    rawInfo,
    "/Library/Application Support/Tachidesk/covers",
  );

  final otherCacheSize = batchFetchStorageSize(rawInfo, [
    "/Library/Caches/$bundleId/WebKit/NetworkCache",
    "/Library/Caches/fsCachedData",
    "/tmp",
    "/Documents/Inbox",
  ]);

  final localSourceSize = fetchStorageSize(
    rawInfo,
    "/Documents/local",
  );

  final downloads1Size = fetchStorageSize(
    rawInfo,
    "/Library/Application Support/Tachidesk/downloads",
  );
  final downloads2Size = fetchStorageSize(
    rawInfo,
    "/Library/Application Support/Tachidesk/downloads2",
  );
  final downloadsSize = (downloads1Size != null || downloads2Size != null)
      ? (downloads1Size ?? 0) + (downloads2Size ?? 0)
      : null;

  final backupSize = fetchStorageSize(
    rawInfo,
    "/Documents/backups",
  );

  int? cacheSize;
  if (imageCacheSize != null) {
    cacheSize = (cacheSize ?? 0) + imageCacheSize;
  }
  if (coverCacheSize != null) {
    cacheSize = (cacheSize ?? 0) + coverCacheSize;
  }
  if (otherCacheSize != null) {
    cacheSize = (cacheSize ?? 0) + otherCacheSize;
  }

  int? otherSize;
  if (totalSize != null) {
    otherSize = totalSize -
        (cacheSize ?? 0) -
        (localSourceSize ?? 0) -
        (downloadsSize ?? 0) -
        (backupSize ?? 0);
  }

  int min = 1001;
  return StorageInfo(
    rawInfo: rawInfo,
    totalSize: totalSize?.toZeroIfLessThan(min),
    cacheSize: cacheSize?.toZeroIfLessThan(min),
    imageCacheSize: imageCacheSize?.toZeroIfLessThan(min),
    coverCacheSize: coverCacheSize?.toZeroIfLessThan(min),
    otherCacheSize: otherCacheSize?.toZeroIfLessThan(min),
    localSourceSize: localSourceSize?.toZeroIfLessThan(min),
    downloadsSize: downloadsSize?.toZeroIfLessThan(min),
    downloadsV1Size: downloads1Size?.toZeroIfLessThan(min),
    backupSize: backupSize?.toZeroIfLessThan(min),
    otherSize: otherSize?.toZeroIfLessThan(min),
  );
}

@riverpod
Future<DownloadMangaQueryOutput?> downloadedMangaInfoList(Ref ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .watch(downloadsRepositoryProvider)
      .batchQueryDownloadMangaInfo(cancelToken: token);
  //await Future.delayed(Duration(seconds: 10));
  return result;
}

@riverpod
AsyncValue<List<StorageDownloadViewModel>?> downloadedMangaViewModelList(
    Ref ref) {
  final mangaInfoListValue = ref.watch(downloadedMangaInfoListProvider);
  final mangaInfoList = mangaInfoListValue.valueOrNull;
  final Map<int, DownloadMangaQueryItem> mangaInfoMap = {};
  for (final DownloadMangaQueryItem info in mangaInfoList?.list ?? []) {
    mangaInfoMap[info.mangaId ?? 0] = info;
  }

  final rawInfoValue = ref.watch(storageRawInfoProvider);
  final rawInfo = rawInfoValue.valueOrNull;
  final mangaDirs = rawInfo
      ?.subDirs?["Library"]
      ?.subDirs?["Application Support"]
      ?.subDirs?["Tachidesk"]
      ?.subDirs?["downloads2"]
      ?.subDirs
      ?.values
      .where((e) => e.subDirs != null)
      .map((e) => e.subDirs!.values)
      .expand((e) => e);

  final list = mangaDirs
      ?.where((e) => (e.size ?? 0) > 0)
      .map((e) {
        final mangaId = int.tryParse(e.name ?? "");
        if (mangaId == null) {
          return StorageDownloadViewModel();
        }
        final info = mangaInfoMap[mangaId];
        Source? source;
        if (info?.sourceIdx != null &&
            mangaInfoList?.sourceList != null &&
            info!.sourceIdx! >= 0 &&
            info.sourceIdx! < mangaInfoList!.sourceList!.length) {
          source = mangaInfoList.sourceList![info.sourceIdx!];
        }
        return StorageDownloadViewModel(
          rawInfo: e,
          mangaId: mangaId,
          inLibrary: info?.inLibrary,
          lastDownloadAt: info?.lastDownloadAt,
          title: info?.title,
          source: source,
          size: e.size,
        );
      })
      .where((e) => e.mangaId != null)
      .toList();
  return mangaInfoListValue.copyWithData((_) => list);
}

@riverpod
class StorageDownloadsQuery extends _$StorageDownloadsQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
AsyncValue<List<StorageDownloadViewModel>?> downloadedMangaViewModelListFilter(
    Ref ref) {
  final query = ref.watch(storageDownloadsQueryProvider);
  final value = ref.watch(downloadedMangaViewModelListProvider);
  final list = value.valueOrNull;

  bool applyFilter(StorageDownloadViewModel viewModel) {
    if (query.isNotBlank == true && viewModel.title?.query(query) != true) {
      return false;
    }
    return true;
  }

  final filtered = list?.where(applyFilter).toList();
  filtered?.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
  return value.copyWithData((p0) => filtered);
}

@riverpod
AsyncValue<List<StorageDownloadViewModel>?> legacyDownloadedMangaViewModelList(
    Ref ref) {
  final rawInfoValue = ref.watch(storageRawInfoProvider);
  final rawInfo = rawInfoValue.valueOrNull;
  final sources = rawInfo
      // /Library/Application Support/Tachidesk/downloads
      ?.subDirs?["Library"]
      ?.subDirs?["Application Support"]
      ?.subDirs?["Tachidesk"]
      ?.subDirs?["downloads"]
      ?.subDirs
      ?.values;
  final list = sources
      ?.where((e) => e.subDirs != null)
      .map((e) {
        return e.subDirs!.values.map((m) {
          return StorageDownloadViewModel(
            rawInfo: m,
            legacyDownload: true,
            mangaId: null,
            title: m.name,
            sourceName: e.name,
            size: m.size,
          );
        });
      })
      .expand((e) => e)
      .where((e) => (e.size ?? 0) > 0)
      .toList();
  return rawInfoValue.copyWithData((_) => list);
}

@riverpod
class StorageLegacyDownloadsQuery extends _$StorageLegacyDownloadsQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
AsyncValue<List<StorageDownloadViewModel>?>
    legacyDownloadedMangaViewModelListFilter(Ref ref) {
  final query = ref.watch(storageLegacyDownloadsQueryProvider);
  final value = ref.watch(legacyDownloadedMangaViewModelListProvider);
  final list = value.valueOrNull;

  bool applyFilter(StorageDownloadViewModel viewModel) {
    if (query.isNotBlank == true && viewModel.title?.query(query) != true) {
      return false;
    }
    return true;
  }

  final filtered = list?.where(applyFilter).toList();
  filtered?.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
  return value.copyWithData((p0) => filtered);
}

@riverpod
Future<List<Manga>?> localSourceMangaList(Ref ref) async {
  final token = CancelToken();
  ref.onDispose(token.cancel);
  final result = await ref
      .read(sourceRepositoryProvider)
      .getMangaList(sourceId: "0", sourceType: SourceType.popular, pageNum: 1);
  return result?.mangaList;
}

@riverpod
AsyncValue<List<StorageLocalMangaViewModel>?> localMangaViewModelList(Ref ref) {
  final mangaListValue = ref.watch(localSourceMangaListProvider);
  final Map<String, Manga> mangaInfoMap = {};
  for (final manga in mangaListValue.valueOrNull ?? []) {
    mangaInfoMap[manga.title ?? ""] = manga;
  }

  final rawInfoValue = ref.watch(storageRawInfoProvider);
  final rawInfo = rawInfoValue.valueOrNull;
  final titles =
      rawInfo?.subDirs?["Documents"]?.subDirs?["local"]?.subDirs?.values;
  final list = titles?.map((e) {
    return StorageLocalMangaViewModel(
      rawInfo: e,
      manga: mangaInfoMap[e.name ?? ""],
    );
  }).toList();
  return rawInfoValue.copyWithData((_) => list);
}

@riverpod
class StorageLocalMangaQuery extends _$StorageLocalMangaQuery
    with StateProviderMixin<String?> {
  @override
  String? build() => null;
}

@riverpod
AsyncValue<List<StorageLocalMangaViewModel>?> localMangaViewModelListFilter(
    Ref ref) {
  final query = ref.watch(storageLocalMangaQueryProvider);
  final value = ref.watch(localMangaViewModelListProvider);
  final list = value.valueOrNull;

  bool applyFilter(StorageLocalMangaViewModel viewModel) {
    if (query.isNotBlank == true &&
        viewModel.rawInfo?.name?.query(query) != true) {
      return false;
    }
    return true;
  }

  final filtered = list?.where(applyFilter).toList();
  filtered
      ?.sort((a, b) => (b.rawInfo?.size ?? 0).compareTo(a.rawInfo?.size ?? 0));
  return value.copyWithData((p0) => filtered);
}
