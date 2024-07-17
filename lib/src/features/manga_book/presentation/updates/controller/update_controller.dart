// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../constants/db_keys.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../../../utils/mixin/state_provider_mixin.dart';
import '../../../../settings/presentation/lab/controller/pip_controller.dart';
import '../../../data/updates/updates_repository.dart';
import '../../../domain/update_status/update_status_model.dart';

part 'update_controller.g.dart';

@riverpod
class CategoryIdsToUpdatePref extends _$CategoryIdsToUpdatePref
    with SharedPreferenceClientMixin<List<String>> {
  @override
  List<String>? build() => initialize(
        ref,
        key: DBKeys.categoryIdsToUpdate.name,
        initial: DBKeys.categoryIdsToUpdate.initial,
      );
}

@riverpod
class AlwaysAskCategoryToUpdatePref extends _$AlwaysAskCategoryToUpdatePref
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
        ref,
        key: DBKeys.alwaysAskCategoryToUpdate.name,
        initial: DBKeys.alwaysAskCategoryToUpdate.initial,
      );
}

@riverpod
class UpdateRunning extends _$UpdateRunning {
  @override
  bool build() {
    final updateStatus = ref.watch(updatesSocketProvider);
    return updateStatus.valueOrNull?.running == true;
  }
}

@riverpod
class UpdateFinalStatus extends _$UpdateFinalStatus {
  @override
  AsyncValue<UpdateStatus?> build() {
    final statusUpdate = ref.watch(updateSummaryProvider);
    final statusUpdateStream = ref.watch(updatesSocketProvider);
    final AsyncValue<UpdateStatus?> finalStatus =
        (statusUpdateStream.valueOrNull?.total.isGreaterThan(0)).ifNull()
            ? statusUpdateStream
            : statusUpdate;
    return finalStatus;
  }
}

@riverpod
class ShowUpdateStatus extends _$ShowUpdateStatus {
  @override
  bool build() {
    final statusUpdate = ref.watch(updateFinalStatusProvider);
    final numberOfJobs = statusUpdate.valueOrNull?.numberOfJobs;
    final completeTimestamp = statusUpdate.valueOrNull?.completeTimestamp;
    final existJobs = numberOfJobs != null && numberOfJobs > 0;
    final active = completeTimestamp == null ||
        completeTimestamp == 0 ||
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - completeTimestamp < 180;
    final switchOn = ref.watch(showUpdateStatusSwitchProvider);
    //log("ShowUpdateStatus existJobs:$existJobs, completeTimestamp:$completeTimestamp, active:$active switchOn:$switchOn");
    return existJobs && active && switchOn;
  }
}

@riverpod
class ShowUpdateStatusSwitch extends _$ShowUpdateStatusSwitch
    with StateProviderMixin<bool> {
  @override
  bool build() {
    ref.keepAlive();
    return true;
  }
}

@riverpod
class UpdateShowPipButton extends _$UpdateShowPipButton {
  @override
  bool build() {
    final enable = ref.watch(pipBuildFlagProvider) == true &&
        ref.watch(bgEnablePrefProvider) == true;
    if (!enable) {
      return false;
    }
    final updateStatus = ref.watch(updatesSocketProvider);
    return updateStatus.valueOrNull?.running == true;
  }
}

@riverpod
class UpdateRefreshSignal extends _$UpdateRefreshSignal {
  bool? prev;

  @override
  bool build() {
    final updateStatus = ref.watch(updatesSocketProvider);
    final running = updateStatus.valueOrNull?.running == true;
    final signal = (prev == true && running == false);
    prev = running;
    return signal;
  }
}
