import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepository;
  late LoginUseCase useCase;

  setUp(() {
    mockRepository = _MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const email = 'test@example.com';
  const password = 'password123';
  const user = User(id: '1', email: email, name: 'Test User');

  test(
    'calls AuthRepository.login with the given email and password',
    () async {
      when(
        () => mockRepository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenReturn(TaskEither.right(user));

      await useCase.call(email: email, password: password).run();

      verify(
        () => mockRepository.login(email: email, password: password),
      ).called(1);
    },
  );

  test('returns the User on success', () async {
    when(
      () => mockRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenReturn(TaskEither.right(user));

    final result = await useCase.call(email: email, password: password).run();

    expect(result, const Right<Failure, User>(user));
  });

  test('returns the Failure on error', () async {
    const failure = ServerFailure('server error');
    when(
      () => mockRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenReturn(TaskEither.left(failure));

    final result = await useCase.call(email: email, password: password).run();

    expect(result, const Left<Failure, User>(failure));
  });
}
