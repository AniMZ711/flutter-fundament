import 'package:flutter/material.dart';

/// Shown while `AuthSessionBloc`'s state is `AuthSessionUnknown`, i.e.
/// before the app has determined whether a session already exists.
///
/// This page never navigates itself — `go_router`'s redirect logic reacts
/// to `AuthSessionBloc` and moves on to `/login` or `/home` once the
/// session state resolves.
class SplashPage extends StatelessWidget {
  /// Creates a [SplashPage].
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
