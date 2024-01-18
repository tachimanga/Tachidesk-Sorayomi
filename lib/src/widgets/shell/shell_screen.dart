// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../constants/enum.dart';
import '../../features/browse_center/presentation/extension/controller/extension_controller.dart';
import '../../features/manga_book/data/downloads/downloads_repository.dart';
import '../../features/manga_book/data/updates/updates_repository.dart';
import '../../features/settings/data/repo/repo_repository.dart';
import '../../features/settings/domain/repo/repo_model.dart';
import '../../global_providers/global_providers.dart';
import '../../global_providers/preference_providers.dart';
import '../../utils/extensions/custom_extensions.dart';
import '../../utils/log.dart';
import '../../utils/misc/toast/toast.dart';
import 'big_screen_navigation_bar.dart';
import 'small_screen_navigation_bar.dart';

class ShellScreen extends HookConsumerWidget {
  const ShellScreen({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extensionUpdate = ref.watch(extensionUpdateProvider);
    final extensionUpdateCount =
        extensionUpdate.valueOrNull?.isGreaterThan(0) == true
            ? extensionUpdate.value!
            : 0;
    setupHandler(context, ref);
    updateMetaUrl(context, ref);

    useOnAppLifecycleStateChange((pref, state) {
      log("useOnAppLifecycleStateChange pref:$pref curr:$state");
      if (state == AppLifecycleState.resumed) {
        ref.invalidate(downloadsSocketProvider);
        ref.invalidate(updatesSocketProvider);
      }
    });
    return context.isTablet
        ? Scaffold(
            body: Row(
              children: [
                BigScreenNavigationBar(
                  selectedScreen: GoRouter.of(context).location,
                  onDestinationSelected: (value) {
                    log("[initLocation]onDestinationSelected $value");
                    ref.read(initLocationProvider.notifier).update(value);
                  },
                  extensionUpdateCount: extensionUpdateCount,
                ),
                Expanded(child: child),
              ],
            ),
          )
        : Scaffold(
            body: child,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            bottomNavigationBar: SmallScreenNavigationBar(
              selectedScreen: GoRouter.of(context).location,
              onDestinationSelected: (value) {
                log("[initLocation]onDestinationSelected $value");
                ref.read(initLocationProvider.notifier).update(value);
              },
              extensionUpdateCount: extensionUpdateCount,
            ),
          );
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
              final param = UpdateByMetaUrlParam(metaUrl: key, targetMetaUrl: value);
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
}
