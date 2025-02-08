// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/endpoints.dart';

bool isValidEmail(String email) {
  if (email.trim().isEmpty) {
    return false;
  }
  if (!email.contains("@")) {
    return false;
  }
  final parts = email.split("@");
  if (parts.length != 2) {
    return false;
  }
  if (parts[0].trim().isEmpty || parts[1].trim().isEmpty) {
    return false;
  }
  if (!parts[1].contains(".")) {
    return false;
  }
  return true;
}