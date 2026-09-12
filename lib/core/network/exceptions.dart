import 'package:dio/dio.dart';

/// Thrown by remote data sources when a request reaches the server but
/// the response indicates failure (4xx/5xx, bad response payload, ...).
class ServerException implements Exception {
  /// Creates a [ServerException] with the given [message].
  const ServerException(this.message);

  /// Developer/log-facing description of what went wrong.
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown by remote data sources when the request never got a response
/// (timeouts, no connection, DNS failure, request cancelled, ...).
class NetworkException implements Exception {
  /// Creates a [NetworkException] with the given [message].
  const NetworkException(this.message);

  /// Developer/log-facing description of what went wrong.
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown by local data sources when reading/writing/clearing cached or
/// securely-stored data fails.
class CacheException implements Exception {
  /// Creates a [CacheException] with the given [message].
  const CacheException(this.message);

  /// Developer/log-facing description of what went wrong.
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Translates a caught [DioException] into a typed data-layer exception.
/// Data sources call this at the point they catch the [DioException] and
/// rethrow the result; the repository then maps that typed exception to a
/// `Failure` via `TaskEither.tryCatch`.
Exception mapDioExceptionToDataException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(e.message ?? 'Network error');
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      return ServerException('Server returned status $statusCode');
    case DioExceptionType.cancel:
      return const NetworkException('Request was cancelled');
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return NetworkException(e.message ?? 'Unknown network error');
  }
}
