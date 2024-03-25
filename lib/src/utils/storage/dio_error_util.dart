// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/db_keys.dart';
import '../extensions/custom_extensions.dart';
import '../log.dart';

const SOCKET_DOWN_MSG = "Unexpected error occurred, please kill the app and then reopen it";

class DioErrorUtil {

  static const pipe = MethodChannel('MAGIC_PIPE');

  // general methods:------------------------------------------------------------
  /// Handles error for Dio Class
  static String handleError(DioError? error, String url) {
    String errorDescription = "";
    final appActive =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    final String prefix = DBKeys.serverUrl.initial;
    final localhost =
        url.startsWith(prefix) && !url.contains("http", prefix.length);
    //print("appActive=$appActive, prefix=$prefix, localhost=$localhost, url=$url");

    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.cancel:
          errorDescription = "Request cancelled";
          break;
        case DioErrorType.connectionTimeout:
          errorDescription = "Connection timeout";
          break;
        case DioErrorType.unknown:
          if (appActive && localhost) {
            errorDescription = SOCKET_DOWN_MSG;
          } else {
            errorDescription = "Check your Internet Connection";
          }
          break;
        case DioErrorType.receiveTimeout:
          errorDescription = "Receive timeout";
          break;
        case DioErrorType.badResponse:
          errorDescription = (error.response?.statusCode) != null
              ? "Received invalid status code: ${error.response?.statusCode}"
              : "Something went wrong!";
          final errMsg = error.response?.headers.value("x-err-msg");
          if (errMsg != null) {
            errorDescription = errMsg;
          }
          final data = error.response?.toString();
          if (data?.isNotEmpty == true) {
            errorDescription = data!;
          }
          break;
        case DioErrorType.sendTimeout:
          errorDescription = "Send timeout";
          break;
        case DioErrorType.badCertificate:
          errorDescription =
              "Check your Internet Connection (Incorrect certificate)";
          break;
        case DioErrorType.connectionError:
          errorDescription =
              "Check your Internet Connection (Connection Error)";
          break;
      }
    } else {
      errorDescription = "Unexpected error occurred";
    }
    return errorDescription;
  }

  static String localizeErrorMessage(String msg, BuildContext context) {
    if (msg == "Blocked by Cloudflare" ||
        msg == "Receive timeout" ||
        msg.startsWith("HTTP error ")) {
      return context.l10n!.checkInWebView(msg);
    }
    return msg;
  }

  static Future<String> recoverSocket(String msg) async {
    if (msg != SOCKET_DOWN_MSG) {
      return msg;
    }
    log("[Socket]recoverSocket ...");
    final r = await pipe.invokeMethod("SOCKET:RESTART");
    log("[Socket]recoverSocket r=$r");
    if (r == true) {
      return "Operation timed out, please retry.";
    }
    return msg;
  }
}
