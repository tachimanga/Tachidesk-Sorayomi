// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../constants/app_sizes.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/urls.dart';

import '../../../../global_providers/global_providers.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../about/presentation/about/widget/media_launch_button.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../widgets/server_url_tile/server_url_tile.dart';
import '../../widgets/theme_mode_tile/theme_mode_tile.dart';
import '../browse/widgets/repo_setting/repo_url_tile.dart';
import 'purchase_cell.dart';

class MoreScreenLite extends HookConsumerWidget {
  const MoreScreenLite({super.key});

  void _onShare(BuildContext context, Toast toast, String text) async {
    toast.instantShow("Loading...");
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(text,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));

    final userDefaults = ref.watch(sharedPreferencesProvider);
    final shareMsg = userDefaults.getString("config.shareMsg") ??
        "Tachimanga (Tachiyomi port for iOS) is now available on the App Store!!! Click this link to download: https://apps.apple.com/app/apple-store/id6447486175?pt=10591908&ct=share&mt=8";
    final pipe = ref.watch(getMagicPipeProvider);
    final magic = ref.watch(getMagicProvider);
    final repoUrlSetting = ref.watch(repoUrlProvider);

    final debugCount = useState(0);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.more),
      ),
      body: ListView(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (debugCount.value++ > 10) {
                context.push([Routes.settings, Routes.debugSettings].toPath);
              }
            },
            child: ImageIcon(
              AssetImage(Assets.icons.darkIcon.path),
              size: context.height * .1,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n!.general),
            leading: const Icon(Icons.tune_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.generalSettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.appearance),
            leading: const Icon(Icons.color_lens_rounded),
            onTap: () => context
                .push([Routes.settings, Routes.appearanceSettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.library),
            leading: const Icon(Icons.collections_bookmark_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.librarySettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.reader),
            leading: const Icon(Icons.chrome_reader_mode_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.readerSettings].toPath),
          ),
          ListTile(
            title: TextPremium(text: context.l10n!.tracking),
            leading: const Icon(Icons.sync_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.trackingSettings].toPath),
          ),
          if (magic.a8 || magic.a9 || repoUrlSetting.isNotBlank) ...[
            ListTile(
              title: Text(context.l10n!.extensions),
              leading: const Icon(Icons.explore_rounded),
              onTap: () =>
                  context.push([Routes.settings, Routes.browseSettings].toPath),
            ),
          ],
          ListTile(
            title: Text(context.l10n!.backup),
            leading: const Icon(Icons.settings_backup_restore_rounded),
            onTap: () => context.push([Routes.settings, Routes.backup].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.downloads),
            leading: const Icon(Icons.download_outlined),
            onTap: () =>
                context.push([Routes.settings, Routes.downloads].toPath),
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n!.share),
            leading: const Icon(Icons.ios_share_rounded),
            onTap: () {
              pipe.invokeMethod("LogEvent", "BTN_SHARE");
              _onShare(context, toast, shareMsg);
            },
          ),
          if (magic.a2) ...[
            ListTile(
                title: Text("Join our telegram group"),
                leading: const Icon(Icons.telegram_rounded),
                onTap: () => launchUrlInWeb(
                      context,
                      AppUrls.telegram.url,
                      ref.read(toastProvider(context)),
                    )),
          ],
          if (magic.a3) ...[
            ListTile(
                title: Text(context.l10n!.discordServer),
                leading: const Icon(Icons.discord_rounded),
                onTap: () => launchUrlInWeb(
                      context,
                      userDefaults.getString("config.discordUrl") ??
                          AppUrls.discord.url,
                      ref.read(toastProvider(context)),
                    )),
          ],
          if (magic.a5) ...[
            ListTile(
              title: Text(context.l10n!.help),
              leading: const Icon(Icons.help_rounded),
              onTap: () => launchUrlInWeb(
                context,
                // 1.7读的是config.helpUrl or discord; 1.8改成faqUrl
                userDefaults.getString("config.faqUrl") ?? AppUrls.faqUrl.url,
                ref.read(toastProvider(context)),
              ),
            ),
          ],
          if (magic.a4) ...[
            ListTile(
              title: Text(context.l10n!.about),
              leading: const Icon(Icons.info_rounded),
              onTap: () => context.push(Routes.about),
            ),
          ],
          if (magic.b3) ...[
            ListTile(
              title: Text(context.l10n!.copyRightClaim),
              leading: const Icon(Icons.email_rounded),
              onTap: () {
                pipe.invokeMethod("LogEvent", "COPYRIGHT_CLAIM");
                pipe.invokeMethod("SEND_MAIL", <String, Object?>{
                  'title': 'Copyright Claim Notice',
                  'content': 'Please provide the following details:\n'
                      'Description of the copyrighted material: [Provide detailed description]\n'
                      'Location of the infringing content: [Provide specific URLs or links]\n',
                });
              },
            ),
          ],
        ],
      ),
    );
  }

}

class TextPremium extends ConsumerWidget {
  const TextPremium({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text.rich(
      TextSpan(text: text, children: [
        WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.ideographic,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 0, 0),
                child: Container(
                  padding: KEdgeInsets.h4.size,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                          width: 0.5)),
                  child: Text("PREMIUM",
                      style: Theme.of(context).textTheme.labelSmall),
                ))),
      ]),
    );
  }
}
