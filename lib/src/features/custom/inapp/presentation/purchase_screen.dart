// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../../constants/app_themes/color_schemas/default_theme.dart';
import '../../../../constants/gen/assets.gen.dart';
import '../../../../constants/language_list.dart';
import '../../../../constants/urls.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/launch_url_in_web.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/radio_list_popup.dart';
import '../../../browse_center/data/settings_repository/settings_repository.dart';
import '../../hex_color.dart';
import '../purchase_providers.dart';

class PurchaseScreen extends HookConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);
    final selectIndex = ref.watch(purchaseSelectIndexProvider);
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

    final commonErrStr = context.l10n!.errorSomethingWentWrong;
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
              child: ListView(children: [
                /*
                ImageIcon(
                  AssetImage(Assets.icons.darkIcon.path),
                  size: context.height * .1,
                ),
                const Divider(),
                ListTile(
                  title: Text(data.config?.title ?? "",
                      style: Theme.of(context).textTheme.headlineSmall),
                  subtitle: Text(data.config?.subTitle ?? ""),
                ),
                */
                ListTile(
                  title: Text(data.config?.subTitle ?? ""),
                ),
                const SizedBox(height: 15),
                ...(data.config?.features ?? []).map((e) => ListTile(
                      visualDensity: const VisualDensity(vertical: -3),
                      title: Text(e),
                      leading:
                          Icon(Icons.star_rounded, color: HexColor("#F2C344")),
                    )),
                const SizedBox(height: 30),
                Container(
                    padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                    child: Row(children: [
                      ...data.productDetails.map((curr) {
                        final index = data.productDetails.indexOf(curr);
                        final item = data.map[curr.id];
                        final title = item != null ? item.title : curr.title;
                        final desc =
                            item != null ? item.desc : curr.description;
                        return Expanded(
                            child: Container(
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                height: 60,
                                child: InkWell(
                                    onTap: () => ref
                                        .read(purchaseSelectIndexProvider
                                            .notifier)
                                        .update(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: index == selectIndex
                                            ? (context.theme.colorScheme.primaryContainer)
                                            : (context.theme.colorScheme.onPrimaryContainer),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 2, vertical: 2),
                                      child: Center(
                                          child: Text(
                                        "${curr.price}${item?.priceSuffix}",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: index != selectIndex
                                              ? (context.theme.colorScheme.primaryContainer)
                                              : (context.theme.colorScheme.onPrimaryContainer),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )),
                                    ))));
                      })
                    ])),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                      child: TextButton(
                    child: Text(context.l10n!.iapFaq),
                    onPressed: () =>
                        launchUrlInWeb(context, AppUrls.iap.url, toast),
                  )),
                  Expanded(
                      child: TextButton(
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
                          detail = "SKError{code: ${e.code}, domain: ${e.domain}, userInfo: ${e.userInfo}";
                        }
                        log("restorePurchases detail:$detail");
                        toast.showError("$commonErrStr\n$detail");
                      }
                    },
                  )),
                ]),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                  child: ElevatedButton(
                    onPressed: (purchaseGate || purchaseState.purchasePending)
                        ? null
                        : () async {
                            final curr = data.productDetails[selectIndex];
                            pipe.invokeMethod("LogEvent", "IAP_TAP_BUY_$selectIndex");
                            try {
                              final param = PurchaseParam(productDetails: curr);
                              final ret = await PurchaseService.purchase(param);
                            } catch (e) {
                              log("purchase err:$e");
                              toast.showError(commonErrStr);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: Text(
                      purchaseGate ? context.l10n!.alreadyGetPremium : context.l10n!.getPremium,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      child: Text(context.l10n!.termsUrl),
                      onPressed: () =>
                          launchUrlInWeb(context, AppUrls.terms.url, toast),
                    ),
                    TextButton(
                      child: Text(context.l10n!.privacyUrl),
                      onPressed: () =>
                          launchUrlInWeb(context, AppUrls.privacy.url, toast),
                    ),
                  ]),
                ),
              ]),
            ),
            refresh: refresh,
            skipLoadingOnReload: true,
          ),
        ));
  }
}
