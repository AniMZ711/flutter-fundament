import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

/// Auth operations available to the domain layer, threading errors as
/// [TaskEither] so no repository method throws.
abstract interface class AuthRepository {
  /// Authenticates with [email]/[password], returning the logged-in [User]
  /// on success.
  TaskEither<Failure, User> login({
    required String email,
    required String password,
  });

  /// Clears the current session.
  TaskEither<Failure, Unit> logout();

  /// Returns the currently cached [User], or [Option.none] if no session
  /// exists yet (e.g. on a fresh app start) — absence here is not an error.
  TaskEither<Failure, Option<User>> getCurrentUser();
}
