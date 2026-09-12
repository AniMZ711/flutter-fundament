import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/core/observer/app_bloc_observer.dart';
import 'package:flutter_fundament/core/theme/app_theme.dart';

/// Shared entrypoint for every flavor's `main_*.dart`: wires DI, the Bloc
/// observer, and starts the app.
Future<void> bootstrap(Env env) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (env.enableVerboseLogging) {
    Bloc.observer = AppBlocObserver();
  }

  configureDependencies(env.flavorName);

  runApp(const _FundamentApp());
}

class _FundamentApp extends StatelessWidget {
  const _FundamentApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Fundament',
      theme: AppTheme.light,
      home: const Placeholder(),
    );
  }
}
