// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../utils/extensions/custom_extensions.dart';

part 'language_model.freezed.dart';
part 'language_model.g.dart';

@freezed
class Language with _$Language {
  Language._();
  factory Language({
    String? code,
    String? name,
    String? nativeName,
  }) = _Language;

  String? get displayName => nativeName ?? name ?? code;
  String? get enName => name ?? code;

  String? localizedDisplayName(BuildContext context) {
    if (code == 'localsourcelang') {
      return context.l10n!.local_source;
    } else if (code == 'installed') {
      return context.l10n!.ext_installed;
    } else if (code == 'lastUsed') {
      return context.l10n!.last_used_source;
    } else if (code == 'pinned') {
      return context.l10n!.pinned_sources;
    } else if (code == 'update') {
      return context.l10n!.ext_updates_pending;
    } else if (code == 'other') {
      return context.l10n!.other_source;
    } else if (code == 'all') {
      return context.l10n!.multi_lang;
    }
    return displayName;
  }

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);
}
