import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepository;
  late LogoutUseCase useCase;

  setUp(() {
    mockRepository = _MockAuthRepository();
    useCase = LogoutUseCase(mockRepository);
  });

  test('calls AuthRepository.logout exactly once', () async {
    when(() => mockRepository.logout()).thenReturn(TaskEither.right(unit));

    await useCase.call().run();

    verify(() => mockRepository.logout()).called(1);
  });

  test('returns unit on success', () async {
    when(() => mockRepository.logout()).thenReturn(TaskEither.right(unit));

    final result = await useCase.call().run();

    expect(result, const Right<Failure, Unit>(unit));
  });

  test('returns the Failure on error', () async {
    const failure = CacheFailure('cache error');
    when(() => mockRepository.logout()).thenReturn(TaskEither.left(failure));

    final result = await useCase.call().run();

    expect(result, const Left<Failure, Unit>(failure));
  });
}
