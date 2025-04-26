// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../constants/enum.dart';
import '../data/updates/updates_repository.dart';
import '../presentation/updates/controller/update_controller.dart';

void fireGlobalUpdate(WidgetRef ref) {
  fireUpdate(ref, []);
}

void fireUpdate(WidgetRef ref, List<String> categoryIds) {
  ref.read(showUpdateStatusSwitchProvider.notifier).update(true);
  if (categoryIds.isEmpty) {
    ref.read(updatesRepositoryProvider).fetchUpdates();
  } else {
    final list = categoryIds.map((e) => int.parse(e)).toList();
    ref.read(updatesRepositoryProvider).fetchUpdates(categoryIds: list);
  }
}

Future<void> retryByCodes(WidgetRef ref, List<String> errorCodes) async {
  ref.read(showUpdateStatusSwitchProvider.notifier).update(true);
  await ref.read(updatesRepositoryProvider).retryByCodes(errorCodes: errorCodes);
}

Future<void> retrySkipped(WidgetRef ref) async {
  ref.read(showUpdateStatusSwitchProvider.notifier).update(true);
  await ref.read(updatesRepositoryProvider).retrySkipped();
}
