import 'package:dio/dio.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/network/auth_interceptor.dart';
import 'package:flutter_fundament/core/network/logging_interceptor.dart';
import 'package:injectable/injectable.dart';

/// Provides the single shared [Dio] instance for the app, wired with
/// [AuthInterceptor] always and [LoggingInterceptor] only outside `prod`.
@module
abstract class NetworkModule {
  /// Builds the app's shared [Dio] client for the given [env].
  @lazySingleton
  Dio dio(Env env, AuthInterceptor authInterceptor) {
    final dio = Dio(BaseOptions(baseUrl: env.apiBaseUrl));
    dio.interceptors.add(authInterceptor);
    if (env.enableVerboseLogging) {
      dio.interceptors.add(LoggingInterceptor());
    }
    return dio;
  }
}
