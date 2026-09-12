import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_fundament/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:injectable/injectable.dart';

/// In-memory stand-in for [AuthRemoteDataSource], used in the `dev` flavor
/// so login works without a real backend. Accepts any non-empty
/// email/password.
@LazySingleton(as: AuthRemoteDataSource, env: [Flavor.dev])
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  /// Creates a [MockAuthRemoteDataSource].
  const MockAuthRemoteDataSource();

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (email.isEmpty || password.isEmpty) {
      throw const ServerException('Invalid email or password');
    }

    return AuthResponseModel(
      token: 'mock-token-${email.hashCode}',
      user: UserModel(id: 'mock-user-1', email: email, name: 'Dev User'),
    );
  }
}
