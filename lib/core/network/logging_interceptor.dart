import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logs request method/URL/status/timing via `dart:developer`'s `log()`.
/// Never logs headers or body, to avoid leaking tokens/PII. Registered
/// only for `dev`/`staging` flavors (see `bootstrap.dart`).
class LoggingInterceptor extends Interceptor {
  final Map<RequestOptions, DateTime> _requestStartTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestStartTimes[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _log(RequestOptions options, int? statusCode) {
    final start = _requestStartTimes.remove(options);
    final elapsedMs = start == null
        ? '?'
        : DateTime.now().difference(start).inMilliseconds.toString();
    developer.log(
      '${options.method} ${options.uri} -> $statusCode (${elapsedMs}ms)',
      name: 'Dio',
    );
  }
}
