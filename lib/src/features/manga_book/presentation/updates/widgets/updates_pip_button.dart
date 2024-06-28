// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/gen/assets.gen.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';

class UpdatesPipButton extends ConsumerWidget {
  const UpdatesPipButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipe = ref.watch(getMagicPipeProvider);

    return IconButton(
      icon: ImageIcon(
        AssetImage(Assets.icons.pip.path),
      ),
      onPressed: () async {
        logEvent3("PIP:UPDATE:START");
        await pipe.invokeMethod("PIP:UPDATE:START");
      },
    );
  }
}
