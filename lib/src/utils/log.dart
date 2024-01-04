import 'dart:developer' as logger;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool logToNativeEnabled = false;
const pipe = MethodChannel('MAGIC_PIPE');

void log(Object? object) {
  if (kDebugMode) {
    print(object);
  } else {
    logger.log("$object");
  }
  if (logToNativeEnabled) {
    pipe.invokeMethod("LOG", "$object");
  }
}