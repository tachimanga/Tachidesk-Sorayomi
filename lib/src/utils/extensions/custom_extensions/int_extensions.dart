// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.
part of '../custom_extensions.dart';

extension IntExtensions on int? {
  bool get isNull => this == null;
  bool get isZero => this != null ? this! == 0 : false;
  bool liesBetween({int lower = 0, int upper = 1}) =>
      this != null ? this! >= lower && this! <= upper : false;
  bool isGreaterThan(int i) => isNull ? false : this! > i;
  bool isLessThan(int i) => isNull ? false : this! < i;
  int ifNullOrNegative([int i = 0]) => isNull || this!.isNegative ? i : this!;
  bool isNotEquals(List<int> lst) =>
      isNull || lst.isBlank ? true : lst.every((e) => e != this);

  bool? get toBool => (this == null || this == 0) ? null : this == 1;

  String? padLeft([int width = 2, String padding = '0']) {
    if (isNull) return null;
    if (this == 0) return toString();
    return toString().padLeft(width, padding);
  }

  String toLocalizedDateString(DateFormatEnum format, BuildContext context) {
    if (isNull) return "";
    return DateFormat(format.code, context.currentLocale.toString())
        .format(DateTime.fromMillisecondsSinceEpoch(this!));
  }

  String toLocalizedDaysAgoFromSeconds(
      DateFormatEnum format, BuildContext context) {
    if (isNull) return "";
    if (this == 0) return "N/A";
    return DateTime.fromMillisecondsSinceEpoch(this! * 1000)
        .convertToLocalizedDaysAgo(format, context);
  }

  String toLocalizedDaysAgo(DateFormatEnum format, BuildContext context) {
    if (isNull) return "";
    if (this == 0) return "N/A";
    return DateTime.fromMillisecondsSinceEpoch(this!)
        .convertToLocalizedDaysAgo(format, context);
  }

  bool isSameDayAs(int? anotherDate) {
    if (isNull || anotherDate.isNull) return false;
    return DateTime.fromMillisecondsSinceEpoch(this! * 1000)
        .isSameDay(DateTime.fromMillisecondsSinceEpoch(anotherDate! * 1000));
  }
}
