import 'package:envied/envied.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:injectable/injectable.dart';

part 'env_prod.g.dart';

/// `prod` flavor's [Env] implementation, backed by `.env.prod`.
@Envied(path: '.env.prod', obfuscate: true)
@LazySingleton(as: Env, env: ['prod'])
class EnvProd implements Env {
  /// Creates the `prod` flavor's [Env].
  const EnvProd();

  @EnviedField(varName: 'API_BASE_URL')
  static final String _apiBaseUrl = _EnvProd._apiBaseUrl;

  @EnviedField(varName: 'ENABLE_VERBOSE_LOGGING')
  static final bool _enableVerboseLogging = _EnvProd._enableVerboseLogging;

  @override
  String get apiBaseUrl => _apiBaseUrl;

  @override
  bool get enableVerboseLogging => _enableVerboseLogging;

  @override
  String get flavorName => Flavor.prod;
}
