import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:svenska/features/main/injection_main.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/constants/app_mode.dart';
import 'core/services/local_label_service.dart';
import 'core/services/server_config_storage.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  ));
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<FlutterSecureStorage>(
          () => const FlutterSecureStorage());
  // Core
  sl.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(sl()),
  );

  sl.registerLazySingleton<ApiClient>(
        () => ApiClient(sl()),
  );

  // injection.dart ke init() function me:
  sl.registerLazySingleton<ServerConfigStorage>(
        () => ServerConfigStorage(sl<FlutterSecureStorage>()),
  );

  if (kUseLocalDataStore) {
    sl.registerLazySingleton<LocalLabelService>(() => LocalLabelService());
  }

  // Features
  await initMainInjection(sl);

}
