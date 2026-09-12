import 'package:flutter_fundament/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// The app's single [GetIt] service locator instance.
final GetIt getIt = GetIt.instance;

/// Initializes [getIt] with the registrations for the given [environment]
/// (one of `Flavor.dev`/`Flavor.staging`/`Flavor.prod`).
@InjectableInit(preferRelativeImports: true)
void configureDependencies(String environment) =>
    getIt.init(environment: environment);
