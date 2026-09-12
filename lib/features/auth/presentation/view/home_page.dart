import 'package:flutter/material.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';

/// Landing page shown once the user is authenticated.
///
/// `go_router`'s redirect logic sends the user back to `/login` once
/// `AuthSessionBloc` transitions to `AuthSessionUnauthenticated` after the
/// logout button below is pressed — this page never navigates itself.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome!'),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('logout_button'),
              onPressed: () => getIt<AuthSessionBloc>().add(
                const AuthSessionEvent.loggedOut(),
              ),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
