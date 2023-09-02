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

import '../../../../constants/language_list.dart';
import '../../../../global_providers/global_providers.dart';
import '../../../../global_providers/preference_providers.dart';
import '../../../../utils/extensions/custom_extensions.dart';
import '../../../../utils/log.dart';
import '../../../../utils/misc/toast/toast.dart';
import '../../../../widgets/custom_circular_progress_indicator.dart';
import '../../../../widgets/emoticons.dart';
import '../../../../widgets/radio_list_popup.dart';
import '../../../browse_center/data/settings_repository/settings_repository.dart';
import '../purchase_providers.dart';

class PurchaseScreen extends HookConsumerWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toast = ref.watch(toastProvider(context));
    final purchaseState = ref.watch(purchaseStateProvider);
    final productList = ref.watch(productsProvider);
    final purchaseDone = ref.watch(purchaseDoneProvider);
    final purchaseExpireMs = ref.watch(purchaseExpireMsProvider);

    var purchaseExpireString = "";
    if (purchaseExpireMs != null && purchaseExpireMs == -1) {
      purchaseExpireString = "lifetime";
    } else if (purchaseExpireMs != null && purchaseExpireMs > 0) {
      final date = DateTime.fromMillisecondsSinceEpoch(purchaseExpireMs);
      purchaseExpireString = "expire at $date";
    }

    refresh() => ref.refresh(productsProvider.future);

    useEffect(() {
      productList.showToastOnError(toast, withMicrotask: true);
      return;
    }, [productList]);

    useEffect(() {
      log("purchase update state: "
          "purchasePending: ${purchaseState.purchasePending}, "
          "error: ${purchaseState.error}");
      if (purchaseState.error != null) {
        toast.close(withMicrotask: true);
        toast.showError(purchaseState.error ?? "", withMicrotask: true);
      } else {
        if (purchaseState.purchasePending) {
          toast.show("Processing...",
              withMicrotask: true,
              gravity: ToastGravity.CENTER,
              toastDuration: const Duration(seconds: 45));
        } else {
          toast.close(withMicrotask: true);
        }
      }
      return;
    }, [purchaseState]);

    final commonErrStr = context.l10n!.errorSomethingWentWrong;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.getPremium),
        actions: [
          IconButton(
            onPressed: () async {
              toast.show("Restore purchase...",
                  gravity: ToastGravity.CENTER,
                  toastDuration: const Duration(seconds: 30));
              try {
                final ret = await PurchaseService.restorePurchases();
              } catch (e) {
                toast.close();
                log("restorePurchases err:$e");
                toast.showError(commonErrStr);
              }
            },
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: purchaseDone ?? false
          ? ListView(
              children: [
                ListTile(
                  title: Text("purchase done"),
                  subtitle: Text(purchaseExpireString),
                  leading: const Icon(Icons.chrome_reader_mode_rounded),
                  onTap: () {},
                ),
              ],
            )
          : productList.showUiWhenData(
              context,
              (data) => RefreshIndicator(
                onRefresh: refresh,
                child: ListView.builder(
                  itemCount: data.productDetails.length,
                  itemBuilder: (context, index) {
                    final curr = data.productDetails[index];
                    final item = data.map[curr.id];
                    final title = item != null ? item.title : curr.title;
                    final desc = item != null ? item.desc : curr.description;
                    return ListTile(
                      title: Text("$title $desc"),
                      subtitle: Text("${curr.price}${item?.priceSuffix}"),
                      onTap: () async {
                        try {
                          final param = PurchaseParam(productDetails: curr);
                          final ret = await PurchaseService.purchase(param);
                        } catch (e) {
                          log("purchase err:$e");
                          toast.showError(commonErrStr);
                        }
                      },
                    );
                  },
                ),
              ),
              refresh: refresh,
            ),
    );
  }
}
