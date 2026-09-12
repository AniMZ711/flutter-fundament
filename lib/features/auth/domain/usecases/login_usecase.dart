import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Authenticates a user with email/password credentials.
@injectable
class LoginUseCase {
  /// Creates a [LoginUseCase] backed by [_repository].
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  /// Runs the use case, forwarding to [AuthRepository.login] unchanged.
  TaskEither<Failure, User> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
