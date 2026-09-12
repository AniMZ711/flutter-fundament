import 'dart:convert';

import 'package:flutter_fundament/core/network/auth_interceptor.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/core/storage/secure_storage.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:injectable/injectable.dart';

/// Storage key under which the cached user's JSON is kept.
const String _cachedUserStorageKey = 'cached_user';

/// Auth session persistence backed by secure, on-device storage.
abstract interface class AuthLocalDataSource {
  /// Persists the session [token] and [user] from a successful login.
  Future<void> cacheSession({required String token, required UserModel user});

  /// Returns the cached user, or `null` if no session has been cached.
  Future<UserModel?> getCachedUser();

  /// Clears any cached session token and user.
  Future<void> clearSession();
}

/// [SecureStorage]-backed implementation of [AuthLocalDataSource].
@LazySingleton(as: AuthLocalDataSource)
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  /// Creates an [AuthLocalDataSourceImpl] backed by [_secureStorage].
  const AuthLocalDataSourceImpl(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> cacheSession({
    required String token,
    required UserModel user,
  }) async {
    try {
      await _secureStorage.write(authTokenStorageKey, token);
      await _secureStorage.write(
        _cachedUserStorageKey,
        jsonEncode(user.toJson()),
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    try {
      final raw = await _secureStorage.read(_cachedUserStorageKey);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(authTokenStorageKey);
      await _secureStorage.delete(_cachedUserStorageKey);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }
}
