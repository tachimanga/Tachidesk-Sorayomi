// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../hex_color.dart';
import '../purchase_providers.dart';

class PurchaseScreen extends HookConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);
    final purchaseGate = ref.watch(purchaseGateProvider);
    final pipe = ref.watch(getMagicPipeProvider);
    final magic = ref.watch(getMagicProvider);

    final productList =
        magic.c2 ? ref.watch(productsV3Provider) : ref.watch(productsProvider);

    Future<void> refresh() async {
      if (magic.c2) {
        ref.refresh(productsApiDataProvider.future);
      } else {
        ref.refresh(productsProvider.future);
      }
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
                    OptionsButton(data: data, selectedIndex: selectedIndex),
                    const SizedBox(height: 2),
                    const Row(children: [
                      Expanded(child: FaqButton()),
                      Expanded(child: RestoreButton()),
                    ]),
                    const SizedBox(height: 2),
                    PurchaseButton(data: data, selectedIndex: selectedIndex),
                    const SizedBox(height: 2),
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
                  child: Center(
                    child: Text(
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
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
      child: FilledButton(
        onPressed: (purchaseGate || purchaseState.purchasePending)
            ? null
            : () async {
                final curr = data.productDetails[selectedIndex.value];
                pipe.invokeMethod(
                    "LogEvent", "IAP_TAP_BUY_${selectedIndex.value}");
                try {
                  final param = PurchaseParam(productDetails: curr);
                  final ret = await PurchaseService.purchase(param);
                } catch (e) {
                  log("purchase err:$e");
                  toast.showError(commonErrStr);
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
