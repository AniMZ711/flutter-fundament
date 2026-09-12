import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Thin typed wrapper around [FlutterSecureStorage] so data sources never
/// touch the raw package API directly.
@lazySingleton
class SecureStorage {
  /// Creates a [SecureStorage] backed by the platform's secure storage.
  SecureStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Reads the value stored under [key], or `null` if absent.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  /// Deletes the value stored under [key].
  Future<void> delete(String key) => _storage.delete(key: key);
}
