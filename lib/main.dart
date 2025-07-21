// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.


import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_proxy/system_proxy.dart';

import 'src/features/about/presentation/about/controllers/about_controller.dart';
import 'src/global_providers/device_providers.dart';
import 'src/global_providers/global_providers.dart';
import 'src/sorayomi.dart';

import 'src/utils/log.dart';


Future<void> main() async {
  // debugRepaintRainbowEnabled = true;
  // debugPaintSizeEnabled=true;
  WidgetsFlutterBinding.ensureInitialized();
  //MobileAds.instance.initialize();
  final packageInfo = await PackageInfo.fromPlatform();
  final sharedPreferences = await SharedPreferences.getInstance();
  final proxy = await SystemProxy.getProxySettings();
  final deviceInfo = await DeviceInfoPlugin().iosInfo;

  // imageCache
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 30 MiB;

  runAppBlock() =>
      runApp(
        ProviderScope(
          overrides: [
            packageInfoProvider.overrideWithValue(packageInfo),
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
            systemProxyProvider.overrideWithValue(proxy),
            deviceInfoProvider.overrideWithValue(deviceInfo),
          ],
          child: const Sorayomi(),
        ),
      );

  final useNativeNet = sharedPreferences.getBool("config.flutterNativeNet");
  final timeout = sharedPreferences.get("config.nativeReqTimeout");
  log("useNativeNet=$useNativeNet, timeout=$timeout");
  if (useNativeNet == null || useNativeNet == true) {
    log("enable flutter native net");
    final config = URLSessionConfiguration.defaultSessionConfiguration();
    config.timeoutIntervalForRequest = Duration(seconds: 15);
    if (timeout != null && timeout is int && timeout > 10) {
      log("set timeout=$timeout");
      config.timeoutIntervalForRequest = Duration(seconds: timeout);
    }
    config.requestCachePolicy = URLRequestCachePolicy.reloadIgnoringLocalCacheData;
    final maxConnPerHostStr = sharedPreferences.getString("config.maxConnPerHost");
    int? maxConnPerHost = maxConnPerHostStr != null
        ? int.tryParse(maxConnPerHostStr)
        : null;
    log("maxConnPerHost $maxConnPerHost");
    if (maxConnPerHost != null) {
      config.httpMaximumConnectionsPerHost = maxConnPerHost;
    }
    final client = CupertinoClient.fromSessionConfiguration(config);
    runWithClient(runAppBlock, () => client);
  } else {
    log("not enable flutter native net");
    runAppBlock();
  }
}