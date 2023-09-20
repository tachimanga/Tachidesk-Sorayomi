// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../constants/app_sizes.dart';
import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../utils/misc/toast/toast.dart';
import '../../../../../widgets/server_image.dart';
import '../../../../custom/hex_color.dart';
import '../../../data/extension_repository/extension_repository.dart';
import '../../../domain/extension/extension_model.dart';
import '../../../domain/extension/extension_tag.dart';
import '../../source/controller/source_controller.dart';

class ExtensionListTile extends HookConsumerWidget {
  const ExtensionListTile({
    super.key,
    required this.extension,
    required this.refresh,
  });

  final Extension extension;
  final AsyncCallback refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(extensionRepositoryProvider);
    final magicPipe = ref.watch(getMagicPipeProvider);
    final isLoading = useState(false);
    return ListTile(
      key: key,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ServerImageWithCpi(
          url: extension.iconUrl ?? "",
          outerSize: const Size.square(48),
          innerSize: const Size.square(24),
          isLoading: isLoading.value,
        ),
      ),
      title: Text(
        extension.name ?? "",
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text.rich(
        TextSpan(
          text: (extension.lang) != null
              ? "${extension.lang?.displayName} "
              : null,
          style: const TextStyle(fontWeight: FontWeight.bold),
          children: [
            if (extension.versionName.isNotBlank)
              TextSpan(
                text: "${extension.versionName ?? ""} ",
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            if (extension.isNsfw.ifNull())
              TextSpan(
                text: context.l10n!.nsfw18,
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (extension.tagList?.isNotEmpty == true) ...[
              for (final tag in extension.tagList!)
                WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    baseline: TextBaseline.ideographic,
                    child: Padding(
                        padding: KEdgeInsets.h4.size,
                        child: Container(
                          padding: KEdgeInsets.h4.size,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  width: 0.5)),
                          child: Text(tag.text ?? ""),
                        ))),
            ]
          ],
        ),
      ),
      trailing: extension.obsolete.ifNull()
          ? OutlinedButton(
              onPressed: extension.installed.ifNull()
                  ? () => repository.uninstallExtension(extension.pkgName!)
                  : null,
              child: Text(
                context.l10n!.obsolete,
                style: const TextStyle(color: Colors.redAccent),
              ),
            )
          : extension.installed.ifNull()
              ? TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          try {
                            isLoading.value = true;
                            (await AsyncValue.guard(
                              () async {
                                if (extension.pkgName.isBlank) {
                                  throw context.l10n!.errorExtension;
                                }
                                if (extension.hasUpdate.ifNull()) {
                                  await repository
                                      .updateExtension(extension.pkgName!);
                                } else {
                                  await repository
                                      .uninstallExtension(extension.pkgName!);
                                }

                                await refresh();
                              },
                            ))
                                .showToastOnError(
                              ref.read(toastProvider(context)),
                            );
                            isLoading.value = false;
                          } catch (e) {
                            //
                          }
                        },
                  child: Text(
                    extension.hasUpdate.ifNull()
                        ? isLoading.value
                            ? context.l10n!.updating
                            : context.l10n!.update
                        : isLoading.value
                            ? context.l10n!.uninstalling
                            : context.l10n!.uninstall,
                  ),
                )
              : TextButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          try {
                            isLoading.value = true;
                            (await AsyncValue.guard(() async {
                              if (extension.pkgName.isBlank) {
                                throw context.l10n!.errorExtension;
                              }
                              await repository
                                  .installExtension(extension.pkgName!);
                              if (extension.lang?.code != null) {
                                final code = extension.lang!.code!;
                                final enabledLanguages = ref.watch(sourceLanguageFilterProvider);
                                if (enabledLanguages != null && !enabledLanguages.contains(code)) {
                                  ref.read(sourceLanguageFilterProvider.notifier).update(
                                    {...enabledLanguages, code}.toList(),
                                  );
                                }
                              }
                              await refresh();
                            }))
                                .showToastOnError(
                              ref.read(toastProvider(context)),
                            );
                            isLoading.value = false;
                          } catch (e) {
                            //
                          }
                        },
                  child: Text(
                    isLoading.value
                        ? context.l10n!.installing
                        : context.l10n!.install,
                  ),
                ),
    );
  }
}
