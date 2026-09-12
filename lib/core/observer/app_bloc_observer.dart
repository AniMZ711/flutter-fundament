import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';

/// Logs `onChange`/`onError` for every Cubit/Bloc via `dart:developer`'s
/// `log()`. Registered only when the active flavor's `env.enableVerboseLogging`
/// getter returns true (true for `dev`/`staging`, false for `prod`).
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    developer.log(
      '${bloc.runtimeType}: ${change.currentState} -> ${change.nextState}',
      name: 'Bloc',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '${bloc.runtimeType}: $error',
      name: 'Bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
