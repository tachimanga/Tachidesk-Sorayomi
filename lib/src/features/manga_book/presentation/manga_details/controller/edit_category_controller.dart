// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../utils/mixin/state_provider_mixin.dart';

part 'edit_category_controller.g.dart';

@riverpod
class LastUsedCategory extends _$LastUsedCategory with StateProviderMixin<Set<String>> {
  @override
  Set<String> build() {
    ref.keepAlive();
    return {};
  }
}
