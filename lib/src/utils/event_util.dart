import 'package:flutter/services.dart';

const channel = MethodChannel('MAGIC_PIPE');

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

void logEvent3(String eventName, [Map<String, String?>? params]) {
  channel.invokeMethod("LogEvent2", <String, Object?>{
    'eventName': eventName,
    'parameters': params,
  });
}