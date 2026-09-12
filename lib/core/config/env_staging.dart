import 'package:envied/envied.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:injectable/injectable.dart';

part 'env_staging.g.dart';

/// `staging` flavor's [Env] implementation, backed by `.env.staging`.
@Envied(path: '.env.staging', obfuscate: true)
@LazySingleton(as: Env, env: ['staging'])
class EnvStaging implements Env {
  /// Creates the `staging` flavor's [Env].
  const EnvStaging();

  @EnviedField(varName: 'API_BASE_URL')
  static final String _apiBaseUrl = _EnvStaging._apiBaseUrl;

  @EnviedField(varName: 'ENABLE_VERBOSE_LOGGING')
  static final bool _enableVerboseLogging = _EnvStaging._enableVerboseLogging;

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  bool get enableVerboseLogging => _enableVerboseLogging;

  @override
  String get flavorName => Flavor.staging;
}
