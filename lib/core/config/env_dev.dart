import 'package:envied/envied.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:injectable/injectable.dart';

part 'env_dev.g.dart';

/// `dev` flavor's [Env] implementation, backed by `.env.dev`.
@Envied(path: '.env.dev', obfuscate: true)
@LazySingleton(as: Env, env: ['dev'])
class EnvDev implements Env {
  /// Creates the `dev` flavor's [Env].
  const EnvDev();

  @EnviedField(varName: 'API_BASE_URL')
  static final String _apiBaseUrl = _EnvDev._apiBaseUrl;

  @EnviedField(varName: 'ENABLE_VERBOSE_LOGGING')
  static final bool _enableVerboseLogging = _EnvDev._enableVerboseLogging;

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  bool get enableVerboseLogging => _enableVerboseLogging;

  @override
  String get flavorName => Flavor.dev;
}
