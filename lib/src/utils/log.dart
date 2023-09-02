import 'dart:developer' as logger;
import 'package:flutter/foundation.dart';

void log(Object? object) {
  if (kDebugMode) {
    print(object);
  } else {
    logger.log("$object");
  }
}