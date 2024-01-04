import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../../../constants/db_keys.dart';
import '../../../global_providers/global_providers.dart';
import '../../../global_providers/locale_providers.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/log.dart';
import '../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../api/api_providers.dart';
import 'model/purchase_model.dart';
part 'purchase_providers.g.dart';

class PurchaseData {
  bool purchasePending = false;
  String? error;
  PurchaseData(this.purchasePending, this.error);
}

@riverpod
class PurchaseState extends _$PurchaseState {
  @override
  PurchaseData build() {
    return PurchaseData(false, null);
  }
  void update(PurchaseData d) {
    log("update state: loading:${d.purchasePending}, err:${d.error}");
    state = d;
  }
}

@riverpod
class PurchaseListener extends _$PurchaseListener {
  @override
  int build() {
    log("purchase listener init");
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    // https://developer.apple.com/documentation/storekit/skpaymenttransactionobserver/1506107-paymentqueue?language=objc
    StreamSubscription<List<PurchaseDetails>> subscription = purchaseUpdated
        .listen((List<PurchaseDetails> purchaseDetailsList) async {
      log("purchase listen result: $purchaseDetailsList");
      for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
        log("purchaseDetails status:${purchaseDetails.status}"
            ", err:${purchaseDetails.error}"
            ", pendingCompletePurchase:${purchaseDetails.pendingCompletePurchase}");
        if (purchaseDetails.status == PurchaseStatus.pending) {
          final d = PurchaseData(true, null);
          ref.read(purchaseStateProvider.notifier).update(d);
        } else {
          if (purchaseDetails.status == PurchaseStatus.error) {
            final d = PurchaseData(false, purchaseDetails.error!.toString());
            ref.read(purchaseStateProvider.notifier).update(d);
          } else if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            final d = PurchaseData(false, null);
            ref.read(purchaseStateProvider.notifier).update(d);
            try {
              await processPurchaseDetail(purchaseDetails);
            } catch (e) {
              log("processPurchaseDetail err $e");
              final d = PurchaseData(false, e.toString());
              ref.read(purchaseStateProvider.notifier).update(d);
            }
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            final d = PurchaseData(false, null);
            ref.read(purchaseStateProvider.notifier).update(d);
          }
          // _pendingCompletePurchase = status != PurchaseStatus.pending;
          // https://developer.apple.com/documentation/storekit/in-app_purchase/original_api_for_in-app_purchase/finishing_a_transaction?language=objc
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
          }
        }
      }
    }, onDone: () {
      log("purchase listener  onDone");
    }, onError: (Object error) {
      log("purchase listener  onError $error");
    });
    ref.onDispose(() {
      log("purchase listener onDispose");
      subscription.cancel();
    });
    ref.keepAlive();
    return 0;
  }

  Future<void> processPurchaseDetail(PurchaseDetails purchaseDetails) async {
    log("processPurchaseDetail transactionDate:${purchaseDetails.transactionDate}"
        ", productID:${purchaseDetails.productID}"
        ", purchaseID:${purchaseDetails.purchaseID}");
    final verificationData = purchaseDetails.verificationData.serverVerificationData;
    log("verificationData $verificationData");
    final verifyResult = await verify(verificationData);
    log("verifyResult $verifyResult");

    if (verifyResult?.valid != true) {
      log("purchaseDone to false");
      ref.read(purchaseDoneProvider.notifier).update(false);
      ref.read(purchaseExpireMsProvider.notifier).update(null);
      ref.read(getMagicPipeProvider)
          .invokeMethod("LogEvent", "VERIFY_ERR_${verifyResult?.msg}");
    } else {
      log("purchaseDone to true");
      ref.read(purchaseDoneProvider.notifier).update(true);
      ref.read(purchaseExpireMsProvider.notifier).update(verifyResult?.expire);
      ref.read(purchaseTokenProvider.notifier).update(verifyResult?.token);
      ref.read(getMagicPipeProvider)
          .invokeMethod("LogEvent", "VERIFY_SUCC");
    }
  }

  Future<VerifyResult?> verify(String verificationData) async {
    final dioClient = ref.watch(dioClientApiProvider);
    final result = (await dioClient.post<VerifyResult, VerifyResult?>(
      "/verify",
      data: {
        "verificationData": verificationData,
      },
      decoder: (e) => e is Map<String, dynamic> ? VerifyResult.fromJson(e) : null,
    )).data;
    return result;
  }
}

class PurchaseService {
  static Future<void> purchase(PurchaseParam purchaseParam) async {
    final r = await InAppPurchase.instance
        .buyNonConsumable(purchaseParam: purchaseParam);
    log("purchase invoke result $r");
  }

  static Future<void> restorePurchases() async {
    await InAppPurchase.instance.restorePurchases();
  }
}

class ProductPageData {
  List<ProductDetails> productDetails;
  ProductListResult? config;
  Map<String, ProductItem> map;
  ProductPageData(this.productDetails, this.config, this.map);
}

@riverpod
Future<ProductPageData> products(ProductsRef ref) async {
  log("purchase load products");

  final dioClient = ref.watch(dioClientApiProvider);
  final locale = ref.watch(userPreferLocaleProvider);
  final result = (await dioClient.post<ProductListResult, ProductListResult?>(
    "/productList",
    data: {
      "language": locale.languageCode,
      "locale": locale.toLanguageTag(),
    },
    decoder: (e) => e is Map<String, dynamic> ? ProductListResult.fromJson(e) : null,
  )).data;

  final map = <String, ProductItem>{};
  var list = ["10", "20", "21"];
  var keys = <String>[];
  if (result != null && result.list != null) {
    for (var value in result.list!) {
      map[value.id ?? ""] = value;
      keys.add(value.id ?? "");
    }
    list = keys;
  }
  log("list order $list");
  log("product map $map");

  final isAvailable = await InAppPurchase.instance.isAvailable();
  if (!isAvailable) {
    throw Exception('InAppPurchase unavailable');
  }
  final ProductDetailsResponse productDetailResponse = await InAppPurchase
      .instance
      .queryProductDetails(list.toSet());
  log("purchase productDetailResponse "
      "productDetails ${productDetailResponse.productDetails}, "
      "notFoundIDs ${productDetailResponse.notFoundIDs}, "
      "error ${productDetailResponse.error}");
  if (productDetailResponse.error != null) {
    throw Exception(productDetailResponse.error.toString());
  }

  var productDetails = <ProductDetails>[];
  for (final id in list) {
    final e = productDetailResponse.productDetails.firstWhereOrNull((element) => element.id == id);
    if (e != null) {
      productDetails.add(e);
    }
  }

  //ref.keepAlive();
  return ProductPageData(productDetails,
    result,
    map
  );
}

@riverpod
class PurchaseDone extends _$PurchaseDone
    with SharedPreferenceClientMixin<bool> {
  @override
  bool? build() => initialize(
    ref,
    key: DBKeys.purchaseDone.name,
    initial: DBKeys.purchaseDone.initial,
  );
}

@riverpod
class PurchaseExpireMs extends _$PurchaseExpireMs
    with SharedPreferenceClientMixin<int> {
  @override
  int? build() => initialize(
    ref,
    key: DBKeys.purchaseExpireMs.name,
    initial: DBKeys.purchaseExpireMs.initial,
  );
}

@riverpod
class PurchaseToken extends _$PurchaseToken
    with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
    ref,
    key: DBKeys.purchaseToken.name,
    initial: DBKeys.purchaseToken.initial,
  );
}

@riverpod
class PurchaseGate extends _$PurchaseGate {
  @override
  bool build() {
    final purchaseDone = ref.watch(purchaseDoneProvider);
    final purchaseExpireMs = ref.watch(purchaseExpireMsProvider);

    var gate = false;
    if (purchaseDone == true) {
      if (purchaseExpireMs != null && purchaseExpireMs == -1) {
        log("lifetime");
        gate = true;
      } else if (purchaseExpireMs != null && purchaseExpireMs > 0) {
        final now = DateTime.now().millisecondsSinceEpoch;
        log("now $now, expire $purchaseExpireMs");
        if (now <= purchaseExpireMs) {
          gate = true;
        }
      }
    } else {
      log("not purchaseDone");
    }
    log("PurchaseGate: purchaseDone $purchaseDone, expire $purchaseExpireMs, gate: $gate");
    return gate;
  }
}

@riverpod
class TestflightFlag extends _$TestflightFlag {
  @override
  bool build() {
    final userDefaults = ref.watch(sharedPreferencesProvider);
    return userDefaults.getString("config.testflight") == "1";
  }
}

@riverpod
class FreeTrialFlag extends _$FreeTrialFlag {
  @override
  bool build() {
    final userDefaults = ref.watch(sharedPreferencesProvider);
    return userDefaults.getString("config.freeTrial") == "1";
  }
}

@riverpod
class PurchaseSelectIndex extends _$PurchaseSelectIndex {
  @override
  int build() {
    return 1;
  }
  void update(int d) {
    state = d;
  }
}
