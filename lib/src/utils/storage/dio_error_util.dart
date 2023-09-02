// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dio/dio.dart';

class DioErrorUtil {
  // general methods:------------------------------------------------------------
  /// Handles error for Dio Class
  static String handleError(DioError? error) {
    String errorDescription = "";
    if (error is DioError) {
      switch (error.type) {
        case DioErrorType.cancel:
          errorDescription = "Request cancelled";
          break;
        case DioErrorType.connectionTimeout:
          errorDescription = "Connection timeout";
          break;
        case DioErrorType.unknown:
          errorDescription = "Unexpected error occurred, please kill the app and then reopen it";
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
          break;
        case DioErrorType.sendTimeout:
          errorDescription = "Send timeout";
          break;
        case DioErrorType.badCertificate:
          errorDescription =
              "Check your Internet Connection (Incorrect certificate )";
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
}
