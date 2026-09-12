import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// Returns the currently cached user, if any.
@injectable
class GetCurrentUserUseCase {
  /// Creates a [GetCurrentUserUseCase] backed by [_repository].
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  /// Runs the use case, forwarding to [AuthRepository.getCurrentUser]
  /// unchanged.
  TaskEither<Failure, Option<User>> call() {
    return _repository.getCurrentUser();
  }
}
