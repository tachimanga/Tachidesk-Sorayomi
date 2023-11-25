import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../data/backup/backup_repository.dart';
import '../../../domain/backup/backup_model.dart';

part 'backup_controller.g.dart';

@riverpod
Future<List<BackupItem>?> backupList(BackupListRef ref) async {
  final pipe = ref.watch(getMagicPipeProvider);
  final str = await pipe.invokeMethod("BACKUP:LIST");
  final result = BackupListResult.fromJson(json.decode(str));
  if (result.succ != true) {
    throw Exception(result.message);
  }
  return result.data?.list;
}

class BackupAction {
  const BackupAction(this.pipe);
  final MethodChannel pipe;

  String convertBackupMessage(Map<String, String> msgMap, String? message) {
    final map = {
      "BACKUP_DB_ERR": "operationFailTip",
      "BACKUP_DB_NOT_VALID": "operationFailTip",
      "BACKUP_CREATE_ZIP_FAIL": "operationFailTip",
      "RESTORE_DB_NOT_VALID": "invalidBackup",
      "BACKUP_FILE_NOT_EXIST": "invalidBackup",
      "BACKUP_FILE_EXTRACT_FAIL": "invalidBackup",
      "BACKUP_FILE_NOT_VALID": "invalidBackup",
      "BACKUP_RESTORE_VERSION_NOT_SUPPORT": "invalidBackupVersion",
      "BACKUP_AUTO_BACKUP_FAIL": "autoBackupFailTip",
    };
    final code = map[message];
    if (code != null) {
      return "${msgMap[code]}($message)";
    }
    return message ?? "";
  }

  // MCBackupTypeManual = 0,
  // MCBackupTypeAuto = 1,
  // MCBackupTypeSchedule = 2,
  Future<void> createBackup(Map<String, String> msgMap, {int type = 0}) async {
    final str = await pipe.invokeMethod("BACKUP:CREATE", {"type": type});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertBackupMessage(msgMap, result.message));
    }
  }

  Future<void> restoreBackup(String name, String path, bool autoBackup,
      Map<String, String> msgMap) async {
    final str = await pipe.invokeMethod("BACKUP:RESTORE",
        {"name": name, "path": path, "autoBackup": autoBackup ? "1" : "0"});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertBackupMessage(msgMap, result.message));
    }
  }

  Future<void> exportBackup(String name, Map<String, String> msgMap) async {
    final str = await pipe.invokeMethod("BACKUP:EXPORT", {"name": name});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertBackupMessage(msgMap, result.message));
    }
  }

  Future<void> deleteBackup(
      int backupId, String backupName, Map<String, String> msgMap) async {
    final str = await pipe
        .invokeMethod("BACKUP:DELETE", {"id": backupId, "name": backupName});
    final result = BackupResult.fromJson(json.decode(str));
    if (result.succ != true) {
      throw Exception(convertBackupMessage(msgMap, result.message));
    }
  }
}

@riverpod
BackupAction backupAction(BackupActionRef ref) =>
    BackupAction(ref.watch(getMagicPipeProvider));

@riverpod
class AutoBackup extends _$AutoBackup with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.autoBackup.name,
        initial: DBKeys.autoBackup.initial,
      );
}

@riverpod
class BackupSocket extends _$BackupSocket {
  @override
  Stream<BackupStatus> build() {
    final pair = ref.watch(backupRepositoryProvider).socketUpdates();
    ref.onDispose(pair.second);
    return pair.first;
  }
}