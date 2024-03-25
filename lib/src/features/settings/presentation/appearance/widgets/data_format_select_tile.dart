// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/enum.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../controller/date_format_controller.dart';

class DateFormatSelectTile extends HookConsumerWidget {
  const DateFormatSelectTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dateFormatPrefProvider) ?? DateFormatEnum.yMMMd;
    final locale = context.currentLocale;
    final now = DateTime.now();
    return ListTile(
      leading: const Icon(Icons.today_rounded),
      title: Text(context.l10n!.pref_date_format),
      subtitle: Text(_getCurrentDataFormatText(now, value, locale)),
      onTap: () => showDialog(
        context: context,
        builder: (context) => RadioListPopup<DateFormatEnum>(
          title: context.l10n!.pref_date_format,
          optionList: DateFormatEnum.values,
          value: value,
          onChange: (value) {
            ref.read(dateFormatPrefProvider.notifier).update(value);
            context.pop();
          },
          optionDisplayName: (e) {
            return e.code;
          },
          optionDisplaySubName: (e) {
            return _getCurrentDataFormatText(now, e, locale);
          },
        ),
      ),
    );
  }

  String _getCurrentDataFormatText(
      DateTime now, DateFormatEnum format, Locale locale) {
    return DateFormat(format.code, locale.toString()).format(now);
  }
}
