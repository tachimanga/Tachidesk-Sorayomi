import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../controller/stroage_controller.dart';
import '../domain/storage_model.dart';

int? fetchStorageSize(StorageRawInfo? info, String path) {
  if (info == null) {
    return null;
  }
  final size = _fetchStorageSize0(info, path);
  return size ?? 0;
}

int? _fetchStorageSize0(StorageRawInfo info, String path) {
  if (path.startsWith("/")) {
    path = path.substring(1, path.length);
  }
  final parts = path.split("/");
  if (parts.isEmpty) {
    return null;
  }
  StorageRawInfo? curr = info;
  for (final p in parts) {
    final t = curr?.subDirs?[p];
    if (t == null) {
      return null;
    }
    curr = t;
  }
  return curr?.size;
}

int? batchFetchStorageSize(StorageRawInfo? info, List<String> paths) {
  if (info == null) {
    return null;
  }
  if (paths.isEmpty) {
    return null;
  }
  int? totalSize;
  for (final path in paths) {
    final size = fetchStorageSize(info, path);
    if (size != null) {
      totalSize = (totalSize ?? 0) + size;
    }
  }
  return totalSize;
}

void invalidStorageProviders(WidgetRef ref) {
  ref.invalidate(storageRawInfoProvider);
  ref.invalidate(storageOverviewInfoProvider);
}