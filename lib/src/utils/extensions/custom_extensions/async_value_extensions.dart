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
    bool skipLoadingOnReload = false,
    String? errorSource,
    Future<String?> Function()? webViewUrlProvider,
  }) {
    if (addScaffoldWrapper) {
      wrapper = (body) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black.withOpacity(.7)),
          body: body);
    }
    return when2(
      skipLoadingOnReload: skipLoadingOnReload,
      data: data,
      error: (error, trace) => wrapper == null
          ? CommonErrorWidget(
              refresh: refresh,
              showGenericError: showGenericError,
              error: error,
              src: errorSource,
              webViewUrlProvider: webViewUrlProvider,
            )
          : wrapper(CommonErrorWidget(
              refresh: refresh,
              showGenericError: showGenericError,
              error: error,
              src: errorSource,
              webViewUrlProvider: webViewUrlProvider,
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

  /// Performs an action based on the state of the [AsyncValue].
  ///
  /// All cases are required, which allows returning a non-nullable value.
  ///
  /// {@template asyncvalue.skip_flags}
  /// By default, [when] skips "loading" states if triggered by a [Ref.refresh]
  /// or [Ref.invalidate] (but does not skip loading states if triggered by [Ref.watch]).
  ///
  /// In the event that an [AsyncValue] is in multiple states at once (such as
  /// when reloading a provider or emitting an error after a valid data),
  /// [when] offers various flags to customize whether it should call
  /// [loading]/[error]/[data] :
  ///
  /// - [skipLoadingOnReload] (false by default) customizes whether [loading]
  ///   should be invoked if a provider rebuilds because of [Ref.watch].
  ///   In that situation, [when] will try to invoke either [error]/[data]
  ///   with the previous state.
  ///
  /// - [skipLoadingOnRefresh] (true by default) controls whether [loading]
  ///   should be invoked if a provider rebuilds because of [Ref.refresh]
  ///   or [Ref.invalidate].
  ///   In that situation, [when] will try to invoke either [error]/[data]
  ///   with the previous state.
  ///
  /// - [skipError] (false by default) decides whether to invoke [data] instead
  ///   of [error] if a previous [value] is available.
  /// {@endtemplate}
  R when2<R>({
    bool skipLoadingOnReload = false,
    bool skipLoadingOnRefresh = true,
    bool skipError = false,
    required R Function(T data) data,
    required R Function(Object error, StackTrace stackTrace) error,
    required R Function() loading,
  }) {
    if (isLoading) {
      bool skip;
      if (isRefreshing) {
        skip = skipLoadingOnRefresh;
        if (hasError) {
          skip = false;
        }
      } else if (isReloading) {
        skip = skipLoadingOnReload;
      } else {
        skip = false;
      }
      if (!skip) return loading();
    }

    if (hasError && (!hasValue || !skipError)) {
      return error(this.error!, stackTrace!);
    }

    return data(requireValue);
  }
}
