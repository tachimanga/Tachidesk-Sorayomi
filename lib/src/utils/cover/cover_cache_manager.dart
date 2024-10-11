import 'dart:async';

import 'package:file/file.dart' hide FileSystem;
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../constants/db_keys.dart';
import '../../features/manga_book/domain/manga/manga_model.dart';
import '../extensions/custom_extensions.dart';
import '../image_util.dart';
import '../log.dart';
import '../manga_cover_util.dart';

/// The DefaultCacheManager that can be easily used directly. The code of
/// this implementation can be used as inspiration for more complex cache
/// managers.
class CoverCacheManager extends CacheManager {
  static const key = 'libCachedImageData';

  static final CoverCacheManager _instance = CoverCacheManager._();

  static final Map<String, int> _refreshMemory = {};

  factory CoverCacheManager() {
    return _instance;
  }

  CoverCacheManager._() : super(Config(key));

  @override
  Stream<FileResponse> getFileStream(String url,
      {String? key,
      Map<String, String>? headers,
      Map<String, String>? extInfo,
      bool withProgress = false}) async* {
    final mangaId = CoverExtInfo.fetchMangaId(extInfo);
    //print("[CacheManager]extInfo child:$extInfo mangaId:$mangaId key:$key");
    if (mangaId == null) {
      //print("[CacheManager] mangaId isnull");
      yield* super.getFileStream(url,
          key: key, headers: headers, withProgress: withProgress);
      return;
    }

    FileInfo? coverFile;
    try {
      coverFile = await getCustomCover(mangaId);
    } on Object catch (e) {
      log('[CacheManager] Failed to load custom cover file for $url with error:\n$e');
    }
    if (coverFile != null) {
      //log("[CacheManager] hit custom coverFile");
      yield coverFile;
      return;
    }

    try {
      coverFile = await getCoverCache(mangaId);
    } on Object catch (e) {
      log('[CacheManager] Failed to load cover file for $url with error:\n$e');
    }
    if (coverFile != null) {
      //log("[CacheManager] hit coverFile");
      yield coverFile;
      return;
    }

    bool inLibrary = CoverExtInfo.fetchInLibrary(extInfo);
    await for (final response in super.getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    )) {
      if (response is DownloadProgress) {
        //print("[CacheManager] yield response");
        yield response;
      }
      if (response is FileInfo) {
        //print("[CacheManager] yield FileInfo");
        if (inLibrary) {
          try {
            await saveCoverCache(mangaId, response);
          } on Object catch (e) {
            log('[CacheManager] Failed to save cover file for $url with error:\n$e');
          }
        }
        yield response;
      }
    }
  }

  Future<FileInfo?> getCoverCache(String mangaId) async {
    //print("[CacheManager] getCoverCache...");

    File file = await buildCoverFile(mangaId);
    final exist = await file.exists();
    if (!exist) {
      return null;
    }
    return FileInfo(
      file,
      FileSource.Cache,
      DateTime.now(),
      "",
    );
  }

  Future<File?> saveCoverCache(String mangaId, FileInfo fileInfo) async {
    //print("[CacheManager] saveCoverCache...");
    File file = await buildCoverFile(mangaId);
    return await fileInfo.file.copy(file.path);
  }

  Future<void> deleteCoverCache(String mangaId) async {
    log("[CacheManager] deleteCoverCache. mangaId=$mangaId");
    File file = await buildCoverFile(mangaId);
    final exist = await file.exists();
    if (exist) {
      await file.delete();
    }
  }

  Future<File> buildCoverFile(String mangaId) async {
    final baseDir = await getApplicationSupportDirectory();
    final path = p.join(baseDir.path, "Tachidesk", "covers");
    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    final file = directory.childFile(mangaId);
    return file;
  }

  Future<FileInfo?> getCustomCover(String mangaId) async {
    //print("[CacheManager] getCustomCover...");

    File file = await buildCustomCoverFile(mangaId);
    final exist = await file.exists();
    if (!exist) {
      return null;
    }
    return FileInfo(
      file,
      FileSource.Cache,
      DateTime.now(),
      "",
    );
  }

  Future<File?> saveCustomCover(String mangaId, String path) async {
    log("[CacheManager] saveCustomCover... mangaId=$mangaId");
    File destFile = await buildCustomCoverFile(mangaId);
    const fs = LocalFileSystem();
    final srcFile = fs.file(path);
    return await srcFile.copy(destFile.path);
  }

  Future<void> deleteCustomCover(String mangaId) async {
    log("[CacheManager] deleteCustomCover mangaId=$mangaId");
    File file = await buildCustomCoverFile(mangaId);
    final exist = await file.exists();
    if (exist) {
      await file.delete();
    }
  }

  Future<File> buildCustomCoverFile(String mangaId) async {
    final baseDir = await getApplicationSupportDirectory();
    final path = p.join(baseDir.path, "Tachidesk", "custom_covers");
    const fs = LocalFileSystem();
    final directory = fs.directory(path);
    final file = directory.childFile(mangaId);
    return file;
  }

  Future<void> onAddToLibrary(Manga manga) async {
    log("[CacheManager] onAddToLibrary... mangaId=${manga.id}");
    try {
      final key = buildImageUrl(
          imageUrl: manga.thumbnailUrl ?? "",
          imageData: manga.thumbnailImg,
          baseUrl: DBKeys.serverUrl.initial);
      log("get file url:$key");
      final file = await getFileFromCache(key);
      if (file != null) {
        saveCoverCache("${manga.id}", file);
      }
    } catch (e) {
      log("[CacheManager] onAddToLibrary err $e");
    }
  }

  Future<void> onRemoveFromLibrary(String mangaId) async {
    log("[CacheManager] onRemoveFromLibrary... mangaId=$mangaId");
    try {
      deleteCoverCache(mangaId);
      deleteCustomCover(mangaId);
    } catch (e) {
      log("[CacheManager] onRemoveFromLibrary err $e");
    }
  }

  Future<bool> shouldRefreshCover(String mangaId) async {
    final customCover = await getCustomCover(mangaId);
    if (customCover != null) {
      return false;
    }
    final ts = _refreshMemory[mangaId];
    if (ts != null && DateTime.now().secondsSinceEpoch - ts < 180) {
      log('[CacheManager] shouldRefreshCover... mangaId=$mangaId hit limit:$ts');
      return false;
    }
    return true;
  }

  Future<void> refreshCover(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? extInfo,
  }) async {
    final mangaId = CoverExtInfo.fetchMangaId(extInfo);
    log('[CacheManager] refreshCover... mangaId=$mangaId');
    if (mangaId == null) {
      return;
    }
    bool inLibrary = CoverExtInfo.fetchInLibrary(extInfo);
    final response = (await downloadFile(url, authHeaders: headers));
    if (inLibrary) {
      try {
        await saveCoverCache(mangaId, response);
      } on Object catch (e) {
        log('[CacheManager] Failed to save cover file for $url with error:\n$e');
      }
    }
    _refreshMemory[mangaId] = DateTime.now().secondsSinceEpoch;
  }
}
