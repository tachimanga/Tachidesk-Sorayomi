import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/enum.dart';
import 'extensions/custom_extensions.dart';

String formatLocalizedDateTime(
    DateFormatEnum format, BuildContext context, int timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  DateFormat formatter =
      DateFormat(format.code, context.currentLocale.toString()).add_Hms();
  return formatter.format(dateTime);
}
