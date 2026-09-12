import 'package:flutter_fundament/core/router/go_router_refresh_stream.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:flutter_fundament/features/auth/presentation/view/home_page.dart';
import 'package:flutter_fundament/features/auth/presentation/view/login_page.dart';
import 'package:flutter_fundament/features/auth/presentation/view/splash_page.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

/// Provides the app's single [GoRouter], wiring [AuthSessionBloc]'s state
/// into redirect-based auth guarding via [GoRouterRefreshStream].
@module
abstract class RouterModule {
  /// Builds the app's [GoRouter].
  @lazySingleton
  GoRouter appRouter(AuthSessionBloc authSessionBloc) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authSessionBloc.stream),
      redirect: (context, state) {
        final authState = authSessionBloc.state;
        final location = state.matchedLocation;
        return switch (authState) {
          AuthSessionUnknown() => location == '/splash' ? null : '/splash',
          AuthSessionAuthenticated() => location == '/home' ? null : '/home',
          AuthSessionUnauthenticated() =>
            location == '/login' ? null : '/login',
        };
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      ],
    );
  }
}
