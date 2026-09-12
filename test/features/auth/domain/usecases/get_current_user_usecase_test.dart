import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepository;
  late GetCurrentUserUseCase useCase;

  setUp(() {
    mockRepository = _MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  const user = User(id: '1', email: 'test@example.com', name: 'Test User');

  test('calls AuthRepository.getCurrentUser exactly once', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenReturn(TaskEither.right(some(user)));

    await useCase.call().run();

    verify(() => mockRepository.getCurrentUser()).called(1);
  });

  test('returns Some(user) when a session exists', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenReturn(TaskEither.right(some(user)));

    final result = await useCase.call().run();

    expect(result, Right<Failure, Option<User>>(some(user)));
  });

  test('returns None when no session exists', () async {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenReturn(TaskEither.right(const None()));

    final result = await useCase.call().run();

    expect(result, const Right<Failure, Option<User>>(None()));
  });

  test('returns the Failure on error', () async {
    const failure = CacheFailure('cache error');
    when(
      () => mockRepository.getCurrentUser(),
    ).thenReturn(TaskEither.left(failure));

    final result = await useCase.call().run();

    expect(result, const Left<Failure, Option<User>>(failure));
  });
}
