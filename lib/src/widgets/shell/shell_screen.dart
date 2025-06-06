// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/enum.dart';
import '../../features/browse_center/presentation/extension/controller/extension_controller.dart';
import '../../features/custom/inapp/purchase_providers.dart';
import '../../features/manga_book/data/downloads/downloads_repository.dart';
import '../../features/manga_book/data/updates/updates_repository.dart';
import '../../features/settings/data/repo/repo_repository.dart';
import '../../features/settings/domain/repo/repo_model.dart';
import '../../features/settings/presentation/backup2/controller/backup_controller.dart';
import '../../features/sync/controller/sync_controller.dart';
import '../../features/sync/data/sync_repository.dart';
import '../../global_providers/global_providers.dart';
import '../../global_providers/preference_providers.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/log.dart';
import '../../utils/premium_reset.dart';
import 'big_screen_navigation_bar.dart';
import 'small_screen_navigation_bar.dart';

final GlobalKey<ScaffoldState> mainScaffoldKey = GlobalKey<ScaffoldState>();
ScrollController get mainPrimaryScrollController =>
    PrimaryScrollController.of(mainScaffoldKey.currentContext!);

var lastSyncAt = 0;

class ShellScreen extends HookConsumerWidget {
  const ShellScreen({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kDebugMode) {
      log("[flutter]ShellScreen build");
    }
    final pipe = ref.watch(getMagicPipeProvider);

    // sync
    final syncWhenAppResume = ref.watch(syncWhenAppResumePrefProvider);
    final syncWhenAppStart = ref.read(syncWhenAppStartPrefProvider);
    final syncPollingInterval = ref.watch(syncPollingIntervalProvider);
    final syncRepository = ref.watch(syncRepositoryProvider);

    final extensionUpdate = ref.watch(extensionUpdateProvider);
    final extensionUpdateCount =
        extensionUpdate.valueOrNull?.isGreaterThan(0) == true
            ? extensionUpdate.value!
            : 0;
    setupHandler(context, ref);
    updateMetaUrl(context, ref);

    if (syncWhenAppStart == true) {
      useEffect(() {
        log("[SYNC]trigger syncWhenAppStart");
        triggerSync(syncRepository);
        return;
      }, []);
    }
    startSyncPollingTimerIfNeeded(syncRepository, syncPollingInterval);

    useOnAppLifecycleStateChange((pref, state) {
      log("useOnAppLifecycleStateChange pref:$pref curr:$state");
      if (state == AppLifecycleState.resumed) {
        ref.invalidate(downloadsSocketProvider);
        ref.invalidate(updatesSocketProvider);
        ref.invalidate(syncSocketProvider);
        if (syncWhenAppResume == true) {
          log("[SYNC]trigger syncWhenAppResume");
          triggerSync(syncRepository);
        }
      }
    });
    return context.isTablet
        ? Scaffold(
            key: mainScaffoldKey,
            body: Row(
              children: [
                BigScreenNavigationBar(
                  selectedScreen: GoRouter.of(context).state.uri.toString(),
                  onDestinationSelected: (value) {
                    log("[initLocation]onDestinationSelected $value");
                    _popModalPopupIfNeeded(context, ref);
                    ref.read(initLocationProvider.notifier).update(value);
                    _sendScreenView(pipe, value);
                  },
                  extensionUpdateCount: extensionUpdateCount,
                ),
                Expanded(child: child),
              ],
            ),
          )
        : Scaffold(
            key: mainScaffoldKey,
            body: child,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomNavigationBar: SmallScreenNavigationBar(
              selectedScreen: GoRouter.of(context).state.uri.toString(),
              onDestinationSelected: (value) {
                log("[initLocation]onDestinationSelected $value");
                _popModalPopupIfNeeded(context, ref);
                ref.read(initLocationProvider.notifier).update(value);
                _sendScreenView(pipe, value);
              },
              extensionUpdateCount: extensionUpdateCount,
            ),
          );
  }

  void _sendScreenView(MethodChannel pipe, String screenName) {
    pipe.invokeMethod<void>('Analytics#logEvent', <String, Object?>{
      'eventName': 'screen_view',
      'parameters': <String, String?>{
        'screen_name': screenName,
        'screen_class': 'Flutter',
      },
    });
  }

  void _popModalPopupIfNeeded(BuildContext context, WidgetRef ref) {
    if (context.canPop() && ref.read(initLocationProvider) != '/more') {
      log("onDestinationSelected popModalPopupIfNeeded");
      context.pop();
    }
  }

  void setupHandler(BuildContext context, WidgetRef ref) {
    final notifyChannel = ref.watch(notifyChannelProvider);
    useEffect(() {
      notifyChannel.setMethodCallHandler((call) async {
        log("notify: ${call.method}, arg: ${call.arguments}");
        if (call.method == 'BYPASS_NOTIFY') {
          if (call.arguments != null && call.arguments is String) {
            if (context.mounted) {
              final code = BypassStatus.fromCode(call.arguments);
              final text = code.toLocale(context);
              if (text != null) {
                Fluttertoast.showToast(
                    msg: text,
                    timeInSecForIosWeb: code == BypassStatus.start ? 5 : 2);
              }
            }
          }
        }
        if (call.method == 'CLOUD_BACKUP_UPDATE') {
          if (context.mounted) {
            ref.read(cloudBackupSocketProvider.notifier).notify();
          }
        }
        return Future.value('OK');
      });
      return;
    }, []);
  }

  void updateMetaUrl(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() async {
        try {
          final userDefaults = ref.read(sharedPreferencesProvider);
          final str = userDefaults.getString("config.repoUpdateStr");
          log("repoUpdateStr str: $str");
          if (str == null || str.isEmpty) {
            return;
          }
          Map<String, dynamic> data = json.decode(str);
          log("repoUpdateStr data: $data");
          data.forEach((key, value) {
            if (value is String) {
              final param = UpdateByMetaUrlParam(
                metaUrl: key,
                targetMetaUrl: value,
              );
              ref.read(repoRepositoryProvider).updateByMetaUrl(param: param);
            }
          });
        } catch (e) {
          log("repoUpdateStr err:$e");
        }
      });
      return;
    }, []);
  }

  void triggerSync(SyncRepository syncRepository) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = (now - lastSyncAt) / 1000;
      log("triggerSync diff=${diff}s");
      if (diff > 30) {
        lastSyncAt = now;
        syncRepository.syncNowIfEnable();
      }
    } catch (e) {
      log("triggerSync err:$e");
    }
  }

  void startSyncPollingTimerIfNeeded(
      SyncRepository syncRepository, int? interval) {
    useEffect(() {
      log("[SYNC]startSyncPollingTimerIfNeeded interval:$interval");
      if (interval == null || interval <= 0) {
        return;
      }
      Timer.periodic(Duration(seconds: interval), (Timer timer) {
        log("[SYNC]trigger sync polling");
        triggerSync(syncRepository);
      });
      return;
    }, []);
  }
}
