// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:cupertino_modal_sheet/cupertino_modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../constants/app_constants.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../icons/icomoon_icons.dart';
import '../../../../routes/router_config.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/shell/shell_screen.dart';
import '../../../../widgets/text_premium.dart';
import '../../../account/controller/account_controller.dart';
import '../../../account/widgets/account_status_tile.dart';
import '../../../custom/inapp/purchase_providers.dart';
import '../../../stats/read_time_stats_screen.dart';
import '../../../sync/controller/sync_controller.dart';
import '../../../sync/widgets/sync_info_widget.dart';
import '../../../sync/widgets/sync_now_tile.dart';
import '../../../sync/widgets/sync_setting_tile.dart';
import '../../controller/edit_repo_controller.dart';
import '../security/controller/security_controller.dart';
import '../security/widgets/incognito_mode_tile.dart';

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
    final userInfoValue = ref.watch(userInfoProvider);
    final userInfo = userInfoValue.valueOrNull;

    final statusValue = ref.watch(syncSocketProvider);
    final syncStatus = statusValue.valueOrNull;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final testflightFlag = ref.watch(testflightFlagProvider);

    final userDefaults = ref.watch(sharedPreferencesProvider);
    final shareMsg = userDefaults.getString("config.shareMsg") ??
        "Tachimanga (an iOS equivalent for Tachiyomi) is now available on the App Store!!! Click this link to download: https://apps.apple.com/app/apple-store/id6447486175?pt=10591908&ct=share&mt=8";
    final pipe = ref.watch(getMagicPipeProvider);
    final magic = ref.watch(getMagicProvider);
    final repoCount = ref.watch(repoCountProvider);

    final showIncognitoMode =
        ref.watch(incognitoModeUsedPrefProvider) == true &&
            (purchaseGate || testflightFlag);

    final debugCount = useState(0);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.more),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (debugCount.value++ > 10) {
                context.push([Routes.settings, Routes.debugSettings].toPath);
              }
            },
            child: const SizedBox(width: 24, height: 24),
          ),
        ],
      ),
      body: ListView(
        controller: mainPrimaryScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          /*
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
          ),*/
          const Divider(),
          if (userInfo?.login == true) ...[
            const AccountStatusTile(),
            if (syncStatus?.enable == true) ...[
              const SyncNowTile(),
            ],
            const Divider(),
          ],
          if (showIncognitoMode) ...[
            const IncognitoModeShortTile(),
          ],
          ListTile(
            title: Text(context.l10n!.general),
            leading: const Icon(Icons.tune_rounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () =>
                context.push([Routes.settings, Routes.generalSettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.appearance),
            leading: const Icon(Icons.color_lens_rounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () => context
                .push([Routes.settings, Routes.appearanceSettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.library),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            leading: const Icon(Icons.collections_bookmark_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.librarySettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.reader),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            leading: const Icon(Icons.chrome_reader_mode_rounded),
            onTap: () =>
                context.push([Routes.settings, Routes.readerSettings].toPath),
          ),
          const SyncSettingTile(),
          ListTile(
            title: TextPremium(text: context.l10n!.tracking),
            leading: const Icon(Icons.sync_rounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () =>
                context.push([Routes.settings, Routes.trackingSettings].toPath),
          ),
          if (magic.a8 || magic.a9 || repoCount > 0) ...[
            ListTile(
              title: Text(context.l10n!.extensions),
              leading: const Icon(Icons.explore_rounded),
              contentPadding: kSettingPadding,
              trailing: kSettingTrailing,
              onTap: () =>
                  context.push([Routes.settings, Routes.browseSettings].toPath),
            ),
          ],
          ListTile(
            title: Text(context.l10n!.backup),
            leading: const Icon(Icons.settings_backup_restore_rounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () => context.push([Routes.settings, Routes.backup].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.pref_category_security),
            leading: const Icon(Icons.security_rounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () =>
                context.push([Routes.settings, Routes.securitySettings].toPath),
          ),
          ListTile(
            title: Text(context.l10n!.reading_insights),
            leading: const Icon(Icons.insights),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () {
              if (context.isTablet) {
                showCupertinoModalSheet(
                  context: context,
                  builder: (context) => const ReadTimeStatsScreen(),
                  routeSettings:
                      const RouteSettings(name: Routes.statsReadTime),
                );
              } else {
                context.push(Routes.statsReadTime);
              }
            },
          ),
          ListTile(
            title: Text(context.l10n!.downloads),
            leading: const Icon(Icons.download_outlined),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () => context.push(Routes.downloads),
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n!.share),
            leading: const Icon(Icomoon.shareRounded),
            contentPadding: kSettingPadding,
            trailing: kSettingTrailing,
            onTap: () {
              pipe.invokeMethod("LogEvent", "BTN_SHARE");
              _onShare(context, toast, shareMsg);
            },
          ),
          if (magic.a2) ...[
            ListTile(
                title: Text("Join our telegram group"),
                leading: const Icon(Icons.telegram_rounded),
                contentPadding: kSettingPadding,
                trailing: kSettingTrailing,
                onTap: () => launchUrlInWeb(
                      context,
                      AppUrls.telegram.url,
                      ref.read(toastProvider(context)),
                    )),
          ],
          if (magic.a5) ...[
            ListTile(
              title: Text(context.l10n!.help),
              leading: const Icon(Icons.help_rounded),
              contentPadding: kSettingPadding,
              trailing: kSettingTrailing,
              onTap: () => launchUrlInWeb(
                context,
                userDefaults.getString("config.faqUrl") ?? AppUrls.faqUrl.url,
                ref.read(toastProvider(context)),
              ),
            ),
          ],
          if (magic.a3) ...[
            ListTile(
                title: Text(context.l10n!.discordServer),
                leading: const Icon(Icons.discord_rounded),
                contentPadding: kSettingPadding,
                trailing: kSettingTrailing,
                onTap: () => launchUrlInWeb(
                      context,
                      userDefaults.getString("config.discordUrl") ??
                          AppUrls.discord.url,
                      ref.read(toastProvider(context)),
                    )),
          ],
          if (magic.a4) ...[
            ListTile(
              title: Text(context.l10n!.about),
              leading: const Icon(Icons.info_outline),
              contentPadding: kSettingPadding,
              trailing: kSettingTrailing,
              onTap: () => context.push(Routes.about),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
