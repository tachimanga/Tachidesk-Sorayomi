// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/endpoints.dart';
import '../features/manga_book/domain/img/image_model.dart';

String buildImageUrl(
    {required String imageUrl, ImgData? imageData, String? baseUrl, bool appendApiToUrl = false}) {
  var baseApi =
      "${Endpoints.baseApi(baseUrl: baseUrl, appendApiToUrl: appendApiToUrl)}"
      "$imageUrl";
  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    baseApi = imageUrl;
  }
  if (imageData?.url != null) {
    baseApi = imageData!.url!;
  }
  return baseApi;
}