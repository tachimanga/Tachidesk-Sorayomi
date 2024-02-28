import 'package:flutter/services.dart';

void logEvent(MethodChannel pipe, String eventName) {
  pipe.invokeMethod("LogEvent", eventName);
}

void logEvent2(
    MethodChannel pipe, String eventName, Map<String, String?> params) {
  pipe.invokeMethod("LogEvent2", <String, Object?>{
    'eventName': eventName,
    'parameters': params,
  });
}