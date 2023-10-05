// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/enum.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../routes/router_config.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/log.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/server_image.dart';
import '../../../data/tracking/tracking_repository.dart';
import '../../../domain/tracking/tracking_model.dart';

class TrackerListTile extends ConsumerWidget {
  const TrackerListTile({
    super.key,
    required this.tracker,
    required this.refresh,
  });

  final Tracker tracker;
  final AsyncCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.read(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ServerImage(
          imageUrl: tracker.icon ?? "",
          size: const Size.square(48),
        ),
      ),
      title: Text(tracker.name ?? ""),
      trailing: (tracker.isLogin == true)
          ? const Icon(
              Icons.check,
              size: 30,
              color: Colors.green,
            )
          : null,
      onTap: () async {
        if (tracker.isLogin == true) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Log out from ${tracker.name}",
                  ),
                  actions: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                            onPressed: () => context.pop(),
                            child: const Text("Cancel")),
                        const SizedBox(
                          width: 15,
                        ),
                        TextButton(
                            onPressed: () async {
                              (await AsyncValue.guard(
                                () async {
                                  await ref
                                      .read(trackingRepositoryProvider)
                                      .logout(tracker.id!);
                                  await refresh();
                                },
                              ))
                                  .showToastOnError(toast);
                              if (context.mounted) {
                                context.pop();
                              }
                            },
                            child: const Text("Log out")),
                      ],
                    )
                  ],
                );
              });
        } else {
          try {
            pipe.invokeMethod("LogEvent", "SET_TRACKER");
            final uri = await FlutterWebAuth2.authenticate(
                url: tracker.authUrl ?? "", callbackUrlScheme: "tachimange");
            toast.show("Processing...",
                gravity: ToastGravity.CENTER,
                toastDuration: const Duration(seconds: 3));
            (await AsyncValue.guard(
              () async {
                await ref
                    .read(trackingRepositoryProvider)
                    .login(tracker.id!, uri);
                await refresh();
                toast.close();
              },
            ))
                .showToastOnError(toast);
          } catch (e) {
            log("auth err $e");
          }
        }
      },
    );
  }
}
