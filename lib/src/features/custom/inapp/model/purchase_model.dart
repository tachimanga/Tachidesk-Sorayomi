// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_model.freezed.dart';
part 'purchase_model.g.dart';

@freezed
class VerifyResult with _$VerifyResult {
  factory VerifyResult({
    bool? valid,
    int? expire,
    String? msg,
    String? token,
  }) = _VerifyResult;

  factory VerifyResult.fromJson(Map<String, dynamic> json) => _$VerifyResultFromJson(json);
}

@freezed
class ProductListResult with _$ProductListResult {
  factory ProductListResult({
    String? title,
    String? subTitle,
    List<String>? features,
    List<ProductItem>? list,
    String? ruleUrl,
  }) = _ProductListResult;

  factory ProductListResult.fromJson(Map<String, dynamic> json) => _$ProductListResultFromJson(json);
}

@freezed
class ProductItem with _$ProductItem {
  factory ProductItem({
    String? id,
    String? title,
    String? desc,
    String? priceSuffix,
  }) = _ProductItem;

  factory ProductItem.fromJson(Map<String, dynamic> json) => _$ProductItemFromJson(json);
}


@freezed
class PurchaseStoreItem with _$PurchaseStoreItem {
  factory PurchaseStoreItem({
    String? purchaseId,
    bool? valid,
    int? expire,
  }) = _PurchaseStoreItem;

  factory PurchaseStoreItem.fromJson(Map<String, dynamic> json) => _$PurchaseStoreItemFromJson(json);
}

@freezed
class PurchaseStoreData with _$PurchaseStoreData {
  factory PurchaseStoreData({
    List<PurchaseStoreItem>? list,
  }) = _PurchaseStoreData;

  factory PurchaseStoreData.fromJson(Map<String, dynamic> json) => _$PurchaseStoreDataFromJson(json);
}
