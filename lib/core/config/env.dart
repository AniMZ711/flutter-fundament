/// Compile-time configuration for the running flavor. Implemented by each
/// flavor's `@Envied`-annotated class so `bootstrap()` and any future code
/// can depend on [Env] polymorphically instead of a specific flavor class.
abstract interface class Env {
  /// The API's base URL for this flavor.
  String get apiBaseUrl;

  /// Whether request/Bloc-transition logging is enabled for this flavor.
  bool get enableVerboseLogging;

  /// One of [Flavor.dev]/[Flavor.staging]/[Flavor.prod]; passed to
  /// `configureDependencies()` so injectable resolves the `@Environment`-
  /// scoped registrations for the running flavor.
  String get flavorName;
}

/// Flavor names, matching the `env: [...]` values on each
/// `EnvDev`/`EnvStaging`/`EnvProd` `@LazySingleton` registration.
abstract final class Flavor {
  /// The `dev` flavor.
  static const dev = 'dev';

  /// The `staging` flavor.
  static const staging = 'staging';

  /// The `prod` flavor.
  static const prod = 'prod';
}
