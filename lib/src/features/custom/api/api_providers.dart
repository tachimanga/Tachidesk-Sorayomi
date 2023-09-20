import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/db_keys.dart';
import '../../../constants/enum.dart';
import '../../../features/settings/presentation/server/widget/credential_popup/credentials_popup.dart';
import '../../../features/settings/widgets/server_url_tile/server_url_tile.dart';
import '../../../global_providers/global_providers.dart';
import '../../../utils/extensions/custom_extensions.dart';
import '../../../utils/mixin/shared_preferences_client_mixin.dart';
import '../../../utils/storage/dio/dio_client.dart';
import '../../../utils/storage/dio/network_module.dart';
import '../../about/presentation/about/controllers/about_controller.dart';

part 'api_providers.g.dart';

@riverpod
DioClient dioClientApi(ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  Dio dio = ref.watch(networkModuleProvider).provideDio(
    baseUrl: ref.watch(serverApiUrlProvider) ?? DBKeys.serverApiUrl.initial,
    authType: AuthType.none,
  );
  dio.options.headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'User-Agent': 'Tachimanga iOS ${packageInfo.version} ${packageInfo.buildNumber}',
  };
  return DioClient(
    dio: dio,
    pipe: ref.watch(getMagicPipeProvider),
  );
}

@riverpod
class ServerApiUrl extends _$ServerApiUrl with SharedPreferenceClientMixin<String> {
  @override
  String? build() => initialize(
    ref,
    key: DBKeys.serverApiUrl.name,
    initial: DBKeys.serverApiUrl.initial,
  );
}
