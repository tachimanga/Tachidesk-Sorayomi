// Copyright (c) 2023 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/multi_select_popup.dart';
import '../../../../../widgets/radio_list_popup.dart';
import '../../../../../widgets/text_field_popup.dart';
import '../../../domain/source_preference/source_preference.dart';
import '../../../domain/source_preference_prop/source_preference_prop.dart';

class SourcePreferenceToWidget extends StatelessWidget {
  const SourcePreferenceToWidget({
    Key? key,
    required this.sourcePreference,
    required this.onChanged,
  }) : super(key: key);

  final SourcePreference sourcePreference;
  final ValueChanged<SourcePreference> onChanged;

  void onChangedPreferenceCopyWith<T extends SourcePreferenceProp>(T prop,
      [BuildContext? context]) {
    onChanged(sourcePreference.copyWith(sourcePreferenceProp: prop));
    if (context != null) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    SourcePreferenceProp? prop = sourcePreference.sourcePreferenceProp;
    if (prop is CheckBoxPreference) {
      return CheckboxListTile(
        key: Key(prop.key ?? ""),
        title: Text(prop.title ?? ""),
        subtitle: prop.summary.isNotBlank ? Text(prop.summary!) : null,
        value: prop.currentValue.ifNull(prop.defaultValue.ifNull()),
        onChanged: (value) =>
            onChangedPreferenceCopyWith(prop.copyWith(currentValue: value)),
        controlAffinity: ListTileControlAffinity.trailing,
      );
    } else if (prop is SwitchPreferenceCompat) {
      return SwitchListTile(
        key: Key(prop.key ?? ""),
        title: Text(prop.title ?? ""),
        subtitle: prop.summary.isNotBlank ? Text(prop.summary!) : null,
        value: prop.currentValue.ifNull(prop.defaultValue.ifNull()),
        onChanged: (value) =>
            onChangedPreferenceCopyWith(prop.copyWith(currentValue: value)),
        controlAffinity: ListTileControlAffinity.trailing,
      );
    } else if (prop is ListPreference) {
      return ListTile(
        key: Key(prop.key ?? ""),
        title: Text(prop.title ?? ""),
        subtitle: prop.currentValue.isNotBlank
            ? Text(prop.entries?[prop.currentValue!] ?? prop.currentValue!)
            : null,
        onTap: () => showDialog(
          context: context,
          builder: (context) => RadioListPopup<String>(
            title: prop.title ?? "",
            optionList: prop.entries?.keys.toList() ?? [],
            value: prop.currentValue ?? prop.defaultValue ?? "",
            onChange: (value) => onChangedPreferenceCopyWith(
                prop.copyWith(currentValue: value), context),
            optionDisplayName: (entry) => prop.entries?[entry] ?? entry,
          ),
        ),
      );
    } else if (prop is MultiSelectListPreference) {
      return ListTile(
        key: Key(prop.key ?? ""),
        title: Text(prop.title ?? ""),
        subtitle: prop.summary.isNotBlank ? Text(prop.summary!) : null,
        onTap: () => showDialog(
          context: context,
          builder: (context) => MultiSelectPopup<String>(
            title: prop.title ?? "",
            optionList: prop.entries?.keys.toList() ?? [],
            values: prop.currentValue ?? prop.defaultValue ?? [],
            onChange: (value) => onChangedPreferenceCopyWith(
                prop.copyWith(currentValue: value), context),
            getOptionTitle: (entry) => prop.entries?[entry] ?? entry,
          ),
        ),
      );
    } else if (prop is EditTextPreference) {
      return ListTile(
        key: Key(prop.key ?? ""),
        title: Text(prop.title ?? ""),
        subtitle: prop.summary.isNotBlank ? Text(prop.summary!) : null,
        onTap: () => showDialog(
          context: context,
          builder: (context) => TextFieldPopup(
            title: prop.dialogTitle ?? prop.title ?? "",
            hint: prop.dialogMessage ?? prop.summary ?? "",
            onChange: (value) => onChangedPreferenceCopyWith(
                prop.copyWith(currentValue: value), context),
            initialValue: prop.currentValue ?? prop.defaultValue,
            textInputAction: TextInputAction.newline,
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
