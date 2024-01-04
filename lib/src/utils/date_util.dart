import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'extensions/custom_extensions.dart';

String formatLocalizedDateTime(BuildContext context, int timestamp) {
  DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  DateFormat formatter =
  DateFormat.yMd(context.currentLocale.toString()).add_Hms();
  return formatter.format(dateTime);
}