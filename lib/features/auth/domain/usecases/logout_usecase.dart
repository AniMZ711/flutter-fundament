import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Clears the current session.
@injectable
class LogoutUseCase {
  /// Creates a [LogoutUseCase] backed by [_repository].
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  /// Runs the use case, forwarding to [AuthRepository.logout] unchanged.
  TaskEither<Failure, Unit> call() {
    return _repository.logout();
  }
}
