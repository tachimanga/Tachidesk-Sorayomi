// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
class CloudUserInfo with _$CloudUserInfo {
  factory CloudUserInfo({
    bool? login,
    String? email,
    String? name,
  }) = _CloudUserInfo;

  factory CloudUserInfo.fromJson(Map<String, dynamic> json) =>
      _$CloudUserInfoFromJson(json);
}

@freezed
class UserRegisterInput with _$UserRegisterInput {
  factory UserRegisterInput({
    String? email,
    String? password,
  }) = _UserRegisterInput;

  factory UserRegisterInput.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterInputFromJson(json);
}

@freezed
class UserLoginInput with _$UserLoginInput {
  factory UserLoginInput({
    String? email,
    String? password,
  }) = _UserLoginInput;

  factory UserLoginInput.fromJson(Map<String, dynamic> json) =>
      _$UserLoginInputFromJson(json);
}

@freezed
class ThirdLoginInput with _$ThirdLoginInput {
  factory ThirdLoginInput({
    String? thirdUserId,
    String? type,
    String? token,
    String? userName,
  }) = _ThirdLoginInput;

  factory ThirdLoginInput.fromJson(Map<String, dynamic> json) =>
      _$ThirdLoginInputFromJson(json);
}

@freezed
class UserLogoutInput with _$UserLogoutInput {
  factory UserLogoutInput({
    bool? logoutAll,
  }) = _UserLogoutInput;

  factory UserLogoutInput.fromJson(Map<String, dynamic> json) =>
      _$UserLogoutInputFromJson(json);
}


@freezed
class UserDeleteInput with _$UserDeleteInput {
  factory UserDeleteInput({
    String? foo,
  }) = _UserDeleteInput;

  factory UserDeleteInput.fromJson(Map<String, dynamic> json) =>
      _$UserDeleteInputFromJson(json);
}