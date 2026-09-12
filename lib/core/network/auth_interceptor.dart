import 'package:dio/dio.dart';
import 'package:flutter_fundament/core/storage/secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Storage key under which the current session's bearer token is kept.
/// Shared with `AuthLocalDataSource` so both read/write the same slot.
const String authTokenStorageKey = 'auth_token';

/// Attaches the bearer token (if any) from [SecureStorage] to every
/// outgoing request.
@injectable
class AuthInterceptor extends Interceptor {
  /// Creates an [AuthInterceptor] reading the bearer token from
  /// [SecureStorage].
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(authTokenStorageKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
