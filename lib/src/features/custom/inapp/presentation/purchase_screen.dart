// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/event_util.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../utils/usage_util.dart';
import '../../hex_color.dart';
import '../purchase_providers.dart';

class PurchaseScreen extends HookConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    final bucket = ref.watch(bucketConfigProvider);
    final productList = ref.watch(productsV3Provider);
    final upgradeToLifetimeSwitch = ref.watch(upgradeToLifetimeSwitchProvider);

    Future<void> refresh() async {
      ref.refresh(productsApiDataProvider.future);
    }

    useEffect(() {
      pipe.invokeMethod("MARK_AD_CLICK");
      return;
    }, []);

    useEffect(() {
      productList.showToastOnError(toast, withMicrotask: true);
      return;
    }, [productList]);

    final processingText = context.l10n!.processing;
    useEffect(() {
      log("purchase update state: "
          "purchasePending: ${purchaseState.purchasePending}, "
          "error: ${purchaseState.error}");
      if (purchaseState.error != null) {
        toast.close(withMicrotask: true);
        toast.showError(purchaseState.error ?? "", withMicrotask: true);
      } else {
        if (purchaseState.purchasePending) {
          toast.show(processingText,
              withMicrotask: true,
              gravity: ToastGravity.CENTER,
              toastDuration: const Duration(seconds: 100));
        } else {
          toast.close(withMicrotask: true);
        }
      }
      return;
    }, [purchaseState]);

    final selectedIndex = useState(1);
    EdgeInsets windowPadding = MediaQuery.paddingOf(context);
    return WillPopScope(
      onWillPop: () async {
        toast.close();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n!.getPremium),
        ),
        body: productList.showUiWhenData(
          context,
          (data) => RefreshIndicator(
            onRefresh: refresh,
            child: Column(children: [
              Expanded(
                child: ListView(
                  children: [
                    if (data.config?.subTitle?.isNotEmpty == true) ...[
                      ListTile(
                        title: Text(data.config?.subTitle ?? ""),
                      ),
                    ],
                    const SizedBox(height: 10),
                    ...(data.config?.features ?? []).map((e) => ListTile(
                          visualDensity: const VisualDensity(vertical: -3),
                          title: Text(e),
                          leading: Icon(
                            Icons.star_rounded,
                            color: HexColor("#F2C344"),
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Material(
                elevation: 8,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    bucket == "c"
                        ? OptionsButton2(
                            data: data, selectedIndex: selectedIndex)
                        : OptionsButton(
                            data: data, selectedIndex: selectedIndex),
                    const SizedBox(height: 2),
                    const Row(children: [
                      Expanded(child: FaqButton()),
                      Expanded(child: RestoreButton()),
                    ]),
                    const SizedBox(height: 2),
                    PurchaseButton(data: data, selectedIndex: selectedIndex),
                    const SizedBox(height: 2),
                    if (upgradeToLifetimeSwitch == true) ...[
                      UpgradeLifeTime(data: data),
                    ],
                    const Footer(),
                    SizedBox(height: max(0, windowPadding.bottom - 14)),
                  ],
                ),
              ),
            ]),
          ),
          refresh: refresh,
          skipLoadingOnReload: true,
        ),
      ),
    );
  }
}

class OptionsButton extends ConsumerWidget {
  const OptionsButton({
    super.key,
    required this.data,
    required this.selectedIndex,
  });

  final ProductPageData data;
  final ValueNotifier<int> selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final colors = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: Row(children: [
        ...data.productDetails.map((curr) {
          final index = data.productDetails.indexOf(curr);
          final item = data.map[curr.id];
          final title = item != null ? item.title : curr.title;
          final desc = item != null ? item.desc : curr.description;
          return Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              height: 60,
              child: GestureDetector(
                onTap: () => selectedIndex.value = index,
                child: Container(
                  decoration: BoxDecoration(
                    // filled_button.dart#_FilledButtonDefaultsM3#backgroundColor
                    color: index == selectedIndex.value && !purchaseGate
                        ? colors.primary
                        : colors.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (curr.id == "10") ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: Colors.yellow.shade300,
                          ),
                          child: Text(
                            context.l10n!.early_bird_price,
                            style: context.textTheme.labelSmall
                                ?.copyWith(color: Colors.black, fontSize: 8),
                          ),
                        ),
                      ],
                      Text(
                        "${curr.price}${item?.priceSuffix}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          // filled_button.dart#_FilledButtonDefaultsM3#foregroundColor
                          color: index == selectedIndex.value && !purchaseGate
                              ? colors.onPrimary
                              : colors.onSurface.withOpacity(0.38),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class OptionsButton2 extends ConsumerWidget {
  const OptionsButton2({
    super.key,
    required this.data,
    required this.selectedIndex,
  });

  final ProductPageData data;
  final ValueNotifier<int> selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseGate = ref.watch(purchaseGateProvider);
    final colors = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: Row(children: [
        ...data.productDetails.map((curr) {
          final index = data.productDetails.indexOf(curr);
          return Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              height: 60,
              child: GestureDetector(
                onTap: () => selectedIndex.value = index,
                child: Container(
                  decoration: BoxDecoration(
                    // filled_button.dart#_FilledButtonDefaultsM3#backgroundColor
                    color: index == selectedIndex.value && !purchaseGate
                        ? colors.primary
                        : colors.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          curr.id.endsWith("0")
                              ? context.l10n!.premium_year_price(curr.price)
                              : context.l10n!.premium_month_price(curr.price),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            // filled_button.dart#_FilledButtonDefaultsM3#foregroundColor
                            color: index == selectedIndex.value && !purchaseGate
                                ? colors.onPrimary
                                : colors.onSurface.withOpacity(0.38),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (curr.id.endsWith("0"))
                          Text(
                            context.l10n!.premium_month_price_only(
                                "${curr.currencySymbol}${(curr.rawPrice / 12).toStringAsFixed(2)}"),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              // filled_button.dart#_FilledButtonDefaultsM3#foregroundColor
                              color:
                                  index == selectedIndex.value && !purchaseGate
                                      ? colors.onPrimary
                                      : colors.onSurface.withOpacity(0.38),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ]),
    );
  }
}

class FaqButton extends ConsumerWidget {
  const FaqButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    return TextButton(
      child: Text(context.l10n!.iapFaq),
      onPressed: () => launchUrlInWeb(context, AppUrls.iap.url, toast),
    );
  }
}

class RestoreButton extends ConsumerWidget {
  const RestoreButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final pipe = ref.watch(getMagicPipeProvider);
    final clearBeforeRestore = ref.watch(clearQueueBeforeRestoreProvider);

    final commonErrStr = context.l10n!.errorSomethingWentWrong;
    return TextButton(
      child: Text(context.l10n!.restorePurchase),
      onPressed: () async {
        log("restorePurchases...");
        pipe.invokeMethod("LogEvent", "IAP_TAP_RESTORE");
        toast.show("Restore purchase...",
            gravity: ToastGravity.CENTER,
            toastDuration: const Duration(seconds: 60));
        try {
          if (clearBeforeRestore == true) {
            await PurchaseService.clearTransactions();
          }
          final ret = await PurchaseService.restorePurchases();
        } catch (e) {
          toast.close();
          log("restorePurchases err:$e");
          var detail = e.toString();
          if (e is SKError) {
            detail =
                "SKError{code: ${e.code}, domain: ${e.domain}, userInfo: ${e.userInfo}";
          }
          log("restorePurchases detail:$detail");
          logEvent3(
            "IAP_TAP_RESTORE_ERROR",
            {"error": (e is SKError) ? "${e.userInfo}" : e.toString()},
          );
          toast.showError("$commonErrStr\n$detail");
        }
      },
    );
  }
}

class PurchaseButton extends ConsumerWidget {
  const PurchaseButton({
    super.key,
    required this.data,
    required this.selectedIndex,
  });

  final ProductPageData data;
  final ValueNotifier<int> selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);
    final purchaseGate = ref.watch(purchaseGateProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    final commonErrStr = context.l10n!.errorSomethingWentWrong;
    final clearBeforeBuy = ref.watch(clearQueueBeforeBuyProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: FilledButton(
        onPressed: (purchaseGate || purchaseState.purchasePending)
            ? null
            : () async {
                final curr = data.productDetails[selectedIndex.value];
                final usageDays = UsageUtil.calculateUsageDays(userDefaults);
                logEvent3(
                  "IAP_TAP_BUY_${selectedIndex.value}",
                  {"x": "$usageDays"},
                );
                try {
                  final did = userDefaults.getString("config.mcdid") ?? '';
                  log("purchase mcdid=$did");
                  final param = PurchaseParam(
                      productDetails: curr, applicationUserName: did);
                  if (clearBeforeBuy == true) {
                    await PurchaseService.clearTransactions();
                  }
                  final ret = await PurchaseService.purchase(param);
                } catch (e) {
                  var detail = e.toString();
                  if (e is SKError) {
                    detail =
                        "SKError{code: ${e.code}, domain: ${e.domain}, userInfo: ${e.userInfo}";
                  }
                  logEvent3(
                    "IAP_TAP_BUY_ERROR",
                    {"error": (e is SKError) ? "${e.userInfo}" : e.toString()},
                  );
                  log("purchase err:$e");
                  toast.showError("$commonErrStr\n$detail");
                }
              },
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: const Size(double.infinity, 60),
        ),
        child: Text(
          purchaseGate
              ? context.l10n!.alreadyGetPremium
              : context.l10n!.getPremium,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class Footer extends ConsumerWidget {
  const Footer({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        TextButton(
          child: Text(context.l10n!.termsUrl),
          onPressed: () => launchUrlInWeb(context, AppUrls.terms.url, toast),
        ),
        TextButton(
          child: Text(context.l10n!.privacyUrl),
          onPressed: () => launchUrlInWeb(context, AppUrls.privacy.url, toast),
        ),
      ]),
    );
  }
}

class UpgradeLifeTime extends HookConsumerWidget {
  const UpgradeLifeTime({
    super.key,
    required this.data,
  });

  final ProductPageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);

    final clearBeforeBuy = ref.watch(clearQueueBeforeBuyProvider);
    final userDefaults = ref.watch(sharedPreferencesProvider);
    final commonErrStr = context.l10n!.errorSomethingWentWrong;

    final purchaseGate = ref.watch(purchaseGateProvider);
    final purchaseExpireMs = ref.watch(purchaseExpireMsProvider);

    final lifetimeOption = data.productDetails
        .where((e) => e.id == "10" || e.id == "11")
        .firstOrNull;
    final canUpgradedToLifeTime = purchaseGate == true &&
        (purchaseExpireMs ?? 0) > 0 &&
        lifetimeOption != null;

    final didTapUpgrade = useState(false);
    final didShowSuccessDialog = useRef(false);

    useEffect(() {
      if (didTapUpgrade.value &&
          (purchaseExpireMs ?? 0) <= 0 &&
          !didShowSuccessDialog.value) {
        didShowSuccessDialog.value = true;
        logEvent3("IAP:UPGRADE:SUCC");
        Future(() {
          if (context.mounted) {
            showUpgradeDialog(context, ref, null);
          }
        });
      }
      return null;
    }, [purchaseExpireMs]);

    if (!canUpgradedToLifeTime) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () async {
              logEvent3("IAP:UPGRADE:TAP:GUIDE");
              showUpgradeDialog(
                context,
                ref,
                () async {
                  if (purchaseState.purchasePending) {
                    return;
                  }
                  final curr = lifetimeOption;
                  try {
                    final did = userDefaults.getString("config.mcdid") ?? '';
                    log("purchase mcdid=$did");
                    final param = PurchaseParam(
                        productDetails: curr, applicationUserName: did);
                    if (clearBeforeBuy == true) {
                      await PurchaseService.clearTransactions();
                    }
                    didTapUpgrade.value = true;
                    final ret = await PurchaseService.purchase(param);
                  } catch (e) {
                    var detail = e.toString();
                    if (e is SKError) {
                      detail =
                          "SKError{code: ${e.code}, domain: ${e.domain}, userInfo: ${e.userInfo}";
                    }
                    logEvent3(
                      "IAP_TAP_BUY_ERROR",
                      {
                        "error": (e is SKError) ? "${e.userInfo}" : e.toString()
                      },
                    );
                    log("purchase err:$e");
                    toast.showError("$commonErrStr\n$detail");
                  }
                },
              );
            },
            child: Text(context.l10n!.how_to_upgrade_lifetime),
          ),
        ],
      ),
    );
  }

  void showUpgradeDialog(
    BuildContext context,
    WidgetRef ref,
    VoidCallback? onTapUpgrade,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(context.l10n!.how_to_upgrade_lifetime),
          content: Text(context.l10n!.how_to_upgrade_lifetime_steps),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n!.cancel),
              onPressed: () {
                ctx.pop();
              },
            ),
            TextButton(
              onPressed: onTapUpgrade != null
                  ? () {
                      ctx.pop();
                      logEvent3("IAP:UPGRADE:TAP:UPGRADE");
                      onTapUpgrade();
                    }
                  : null,
              child: Text(context.l10n!.upgrade_label),
            ),
            TextButton(
              onPressed: onTapUpgrade == null
                  ? () {
                      logEvent3("IAP:UPGRADE:TAP:MANAGE");
                      launchUrlInSafari(
                        context,
                        "https://apps.apple.com/account/subscriptions",
                        ref.read(toastProvider(context)),
                      );
                      ctx.pop();
                    }
                  : null,
              child: Text(context.l10n!.subscription_management),
            ),
          ],
        );
      },
    );
  }
}
