// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../../constants/app_sizes.dart';
import '../../../../../../global_providers/global_providers.dart';
import '../../../../../../routes/router_config.dart';
import '../../../../../../utils/event_util.dart';
import '../../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../../utils/log.dart';
import '../../../../../../utils/misc/toast/toast.dart';
import '../../../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../../../widgets/pop_button.dart';
import '../../../../../browse_center/presentation/extension/controller/extension_controller.dart';
import '../../../../controller/edit_repo_controller.dart';
import '../../../../controller/remote_blacklist_controller.dart';
import '../../../../data/config/remote_blacklist_config.dart';
import '../../../../data/repo/repo_repository.dart';
import '../../../../domain/repo/repo_model.dart';
import '../repo_setting/repo_url_tile.dart';
import 'aggrement_radio_list_tile.dart';

class AddRepoDialogAgreementDialog extends HookConsumerWidget {
  const AddRepoDialogAgreementDialog({
    super.key,
    required this.parts,
    required this.onAgreed,
  });

  final List<String> parts;
  final VoidCallback onAgreed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = parts.skip(1).toList();
    final states = list.map((e) => useState(false)).toList();
    final shakes = list.map((e) => useState<UniqueKey?>(null)).toList();

    return AlertDialog(
      title: Text(parts[0]),
      titleTextStyle: context.textTheme.titleLarge?.copyWith(fontSize: 18),
      content: _buildAgreementContent(context, list, states, shakes),
      actions: [
        PopButton(
          popText: context.l10n!.disagree_label,
        ),
        ElevatedButton(
          onPressed: () {
            final disagree = states.any((e) => e.value != true);
            if (disagree) {
              for (var i = 0; i < states.length; i++) {
                if (states[i].value != true) {
                  shakes[i].value = UniqueKey();
                  break;
                }
              }
            } else {
              onAgreed();
            }
          },
          child: Text(context.l10n!.agree_label),
        ),
      ],
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
    );
  }

  Widget _buildAgreementContent(
    BuildContext context,
    List<String> parts,
    List<ValueNotifier<bool>> states,
    List<ValueNotifier<UniqueKey?>> shakes,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      final widget = AgreementRadioListTile(
        title: Text(
          parts[i],
          style: context.textTheme.bodySmall,
        ),
        value: states[i].value,
        groupValue: true,
        onChanged: (value) {
          states[i].value = value != null ? !value : false;
        },
        toggleable: true,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );

      widgets.add(ShakeWidget(
        key: shakes[i].value,
        child: widget,
      ));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

class ShakeWidget extends StatelessWidget {
  final Duration duration;
  final double deltaX;
  final Widget child;
  final Curve curve;

  const ShakeWidget({
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.deltaX = 20,
    this.curve = Curves.bounceOut,
    required this.child,
  });

  /// convert 0-1 to 0-1-0
  double shake(double animation) =>
      2 * (0.5 - (0.5 - curve.transform(animation)).abs());

  @override
  Widget build(BuildContext context) {
    if (key == null) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, animation, child) => Transform.translate(
        offset: Offset(deltaX * shake(animation), 0),
        child: child,
      ),
      child: child,
    );
  }
}
