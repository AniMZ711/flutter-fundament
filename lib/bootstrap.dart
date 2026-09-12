import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/core/observer/app_bloc_observer.dart';
import 'package:flutter_fundament/core/theme/app_theme.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:go_router/go_router.dart';

/// Shared entrypoint for every flavor's `main_*.dart`: wires DI, the Bloc
/// observer, and starts the app.
Future<void> bootstrap(Env env) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (env.enableVerboseLogging) {
    Bloc.observer = AppBlocObserver();
  }

  configureDependencies(env.flavorName);

  getIt<AuthSessionBloc>().add(const AuthSessionEvent.appStarted());

  runApp(const _FundamentApp());
}

class _FundamentApp extends StatelessWidget {
  const _FundamentApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Fundament',
      theme: AppTheme.light,
      routerConfig: getIt<GoRouter>(),
    );
  }
}
