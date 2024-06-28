import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../constants/enum.dart';
import '../features/custom/inapp/purchase_providers.dart';
import '../features/manga_book/presentation/downloads/controller/downloads_controller.dart';
import '../features/manga_book/presentation/reader/controller/reader_setting_controller.dart';
import '../features/settings/presentation/appearance/constants/theme_define.dart';
import '../features/settings/presentation/appearance/controller/theme_controller.dart';
import '../features/settings/presentation/backup2/controller/auto_backup_controller.dart';
import '../features/settings/presentation/security/controller/security_controller.dart';
import '../routes/router_config.dart';
import 'log.dart';

class PremiumReset {
  static PremiumReset instance = PremiumReset();

  void resetWhenStartup(WidgetRef ref) {
    try {
      log("[Premium]resetWhenStartup");
      _resetPremiumSwitch(ref);
    } catch (e) {
      log("[Premium]resetWhenStartup error $e");
    }
  }

  void resetWhenSwitchTab(String current, WidgetRef ref) {
    try {
      log("[Premium]resetWhenSwitchTab current:$current");
      if ([Routes.more, Routes.settings]
          .any((element) => current.contains(element))) {
        _resetPremiumSwitch(ref);
      }
    } catch (e) {
      log("[Premium]resetWhenSwitchTab error $e");
    }
  }

  void _resetPremiumSwitch(WidgetRef ref) {
    log("[Premium]_resetPremiumSwitch");
    final purchaseGate = ref.read(purchaseGateProvider);
    final testflightFlag = ref.read(testflightFlagProvider);
    if (purchaseGate || testflightFlag) {
      return;
    }
    if (ref.read(themeKeyProvider) != ThemeDefine.defaultSchemeKey) {
      log("reset themeKeyProvider");
      Future(() {
        ref
            .read(themeKeyProvider.notifier)
            .update(ThemeDefine.defaultSchemeKey);
      });
    }
    if (ref.read(themePureBlackProvider) == true) {
      log("reset themePureBlackProvider");
      Future(() {
        ref.read(themePureBlackProvider.notifier).update(false);
      });
    }
    if (ref.read(autoBackupFrequencyProvider) != FrequencyEnum.off) {
      log("reset autoBackupFrequencyProvider");
      Future(() {
        ref
            .read(autoBackupFrequencyProvider.notifier)
            .update(FrequencyEnum.off);
      });
    }

    if (ref.read(lockTypePrefProvider) != LockTypeEnum.off) {
      log("reset lockTypePrefProvider");
      Future(() {
        ref.read(lockTypePrefProvider.notifier).update(LockTypeEnum.off);
      });
    }
    if (ref.read(secureScreenPrefProvider) != SecureScreenEnum.off) {
      log("reset secureScreenPrefProvider");
      Future(() {
        ref
            .read(secureScreenPrefProvider.notifier)
            .update(SecureScreenEnum.off);
      });
    }
    if (ref.read(incognitoModePrefProvider) == true) {
      log("reset incognitoModePrefProvider");
      Future(() {
        ref.read(incognitoModePrefProvider.notifier).update(false);
      });
    }

    if (ref.read(readerPageLayoutPrefProvider) != ReaderPageLayout.singlePage) {
      log("reset readerPageLayoutPrefProvider");
      Future(() {
        ref
            .read(readerPageLayoutPrefProvider.notifier)
            .update(ReaderPageLayout.singlePage);
      });
    }
  }
}
