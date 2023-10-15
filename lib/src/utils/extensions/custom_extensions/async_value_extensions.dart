// Copyright (c) 2022 Contributors to the Suwayomi project
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

part of '../custom_extensions.dart';

extension AsyncValueExtensions<T> on AsyncValue<T> {
  void _showToastOnError(Toast toast) {
    if (!isRefreshing) {
      whenOrNull(
        error: (error, stackTrace) {
          toast.close();
          toast.showError(error.toString());
        },
      );
    }
  }

  void showToastOnError(Toast toast, {bool withMicrotask = false}) {
    if (withMicrotask) {
      Future.microtask(() => (this._showToastOnError(toast)));
    } else {
      this._showToastOnError(toast);
    }
  }

  T? valueOrToast(Toast toast, {bool withMicrotask = false}) =>
      (this..showToastOnError(toast, withMicrotask: withMicrotask)).valueOrNull;

  Widget showUiWhenData(
    BuildContext context,
    Widget Function(T data) data, {
    VoidCallback? refresh,
    Widget Function(Widget)? wrapper,
    bool showGenericError = false,
    bool addScaffoldWrapper = false,
    String? errorSource,
    String? webViewUrl,
  }) {
    if (addScaffoldWrapper) {
      wrapper = (body) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black.withOpacity(.7)),
          body: body);
    }
    return when(
      data: data,
      error: (error, trace) => wrapper == null
          ? CommonErrorWidget(
              refresh: refresh,
              showGenericError: showGenericError,
              error: error,
              src: errorSource,
              url: webViewUrl,
            )
          : wrapper(CommonErrorWidget(
              refresh: refresh,
              showGenericError: showGenericError,
              error: error,
              src: errorSource,
              url: webViewUrl,
            )),
      loading: () => wrapper == null
          ? const CenterCircularProgressIndicator()
          : wrapper(const CenterCircularProgressIndicator()),
    );
  }

  AsyncValue<U> copyWithData<U>(U Function(T) data) => when(
        data: (prev) => AsyncData(data(prev)),
        error: (error, stackTrace) => AsyncError<U>(error, stackTrace),
        loading: () => AsyncLoading<U>(),
      );
}
