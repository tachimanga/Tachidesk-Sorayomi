// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';

import '../../../../../utils/extensions/custom_extensions.dart';
import '../../../../../widgets/server_image.dart';
import '../../../domain/extension/extension_model.dart';

class ExtensionDescriptiveListTile extends StatelessWidget {
  const ExtensionDescriptiveListTile({
    super.key,
    required this.extension,
  });
  final Extension extension;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: ServerImage(
              imageUrl: extension.iconUrl ?? "",
            ),
          ),
          Text(
            extension.name ?? "",
            style: context.textTheme.titleLarge,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            extension.pkgName
                    ?.replaceAll("eu.kanade.tachiyomi.extension.", "") ??
                "",
            style: context.textTheme.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      Text(
                        extension.versionName ?? "",
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        "Version",
                        style: context.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  )),
                  Expanded(
                      child: Column(
                    children: [
                      Text(
                        "${extension.lang?.displayName}",
                        style: context.textTheme.titleMedium,
                      ),
                      Text(
                        "Language",
                        style: context.textTheme.titleMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  )),
                ],
              )),
          const Divider(),
        ],
      ),
    );
  }
}
