import 'package:flutter/material.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/di/injection.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/core/theme/app_theme.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_fundament/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

const _validEmail = 'user@example.com';
const _validPassword = 'password123';

/// A fake [AuthRemoteDataSource] standing in for a real backend, so this
/// end-to-end flow can run without a network dependency: accepts one known
/// email/password pair, rejects everything else with a [ServerException]
/// (mirroring how [AuthRemoteDataSourceImpl] rethrows on a bad response).
class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    if (email == _validEmail && password == _validPassword) {
      return const AuthResponseModel(
        token: 'fake-token',
        user: UserModel(id: '1', email: _validEmail, name: 'Test User'),
      );
    }
    throw const ServerException('Invalid credentials');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login -> guarded home -> logout -> redirect back to login', (
    tester,
  ) async {
    WidgetsFlutterBinding.ensureInitialized();
    configureDependencies(Flavor.dev);

    // Swap the network-backed remote data source for the fake BEFORE
    // anything in the auth DI graph is first resolved (everything is
    // registered lazily, but AuthSessionBloc.add below forces the whole
    // chain — repository, mapper, both data sources — to construct; the
    // swap must happen first or the real one gets wired in instead).
    getIt
      ..unregister<AuthRemoteDataSource>()
      ..registerLazySingleton<AuthRemoteDataSource>(
        _FakeAuthRemoteDataSource.new,
      );

    // Start from a clean slate regardless of any session left over from
    // a previous run on this simulator/device.
    await getIt<AuthLocalDataSource>().clearSession();

    getIt<AuthSessionBloc>().add(const AuthSessionEvent.appStarted());

    await tester.pumpWidget(
      MaterialApp.router(
        title: 'Flutter Fundament',
        theme: AppTheme.light,
        routerConfig: getIt<GoRouter>(),
      ),
    );
    await tester.pumpAndSettle();

    // No session -> redirected from /splash to /login.
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      _validEmail,
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      _validPassword,
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    // Login succeeded -> AuthSessionBloc flips to authenticated ->
    // redirected to /home.
    expect(find.byKey(const Key('logout_button')), findsOneWidget);
    expect(find.byKey(const Key('login_email_field')), findsNothing);

    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();

    // Logged out -> redirected back to /login.
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('logout_button')), findsNothing);
  });
}
