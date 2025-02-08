import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../constants/endpoints.dart';
import '../../features/about/presentation/about/controllers/about_controller.dart';
import '../../features/sync/controller/sync_controller.dart';
import '../../global_providers/global_providers.dart';
import '../../utils/storage/dio/dio_client.dart';
import '../../utils/storage/dio/network_module.dart';


part 'api3_providers.g.dart';

@riverpod
DioClient dioClientApi3(ref) {
  final packageInfo = ref.watch(packageInfoProvider);
  Dio dio = ref.watch(networkModuleProvider).provideDio3(
    host: ref.watch(cloudServerPrefProvider) ?? Endpoints.api3host,
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