import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_cubit.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_presentation_event.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoginUseCase extends Mock implements LoginUseCase {}

class _MockAuthSessionBloc extends MockBloc<AuthSessionEvent, AuthSessionState>
    implements AuthSessionBloc {}

void main() {
  late _MockLoginUseCase mockLoginUseCase;
  late _MockAuthSessionBloc mockAuthSessionBloc;

  const email = 'test@example.com';
  const password = 'password123';
  const user = User(id: '1', email: email, name: 'Test User');

  setUpAll(() {
    registerFallbackValue(const AuthSessionEvent.appStarted());
  });

  setUp(() {
    mockLoginUseCase = _MockLoginUseCase();
    mockAuthSessionBloc = _MockAuthSessionBloc();
  });

  group('submit', () {
    blocTest<LoginCubit, LoginState>(
      'emits [submitting, success] and dispatches AuthSessionEvent.loggedIn '
      'on success, with no presentation event',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenReturn(TaskEither.right(user));
      },
      build: () => LoginCubit(mockLoginUseCase, mockAuthSessionBloc),
      act: (cubit) => cubit.submit(email: email, password: password),
      expect: () => [
        const LoginState.submitting(),
        const LoginState.success(user),
      ],
      verify: (_) {
        verify(
          () => mockAuthSessionBloc.add(const AuthSessionEvent.loggedIn(user)),
        ).called(1);
      },
    );

    blocTest<LoginCubit, LoginState>(
      'emits [submitting, failure] and emits a ShowErrorSnackbar '
      'presentation event on failure, without touching AuthSessionBloc',
      setUp: () {
        when(
          () => mockLoginUseCase(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenReturn(TaskEither.left(const ServerFailure('server error')));
      },
      build: () => LoginCubit(mockLoginUseCase, mockAuthSessionBloc),
      act: (cubit) => cubit.submit(email: email, password: password),
      expect: () => [
        const LoginState.submitting(),
        const LoginState.failure(ServerFailure('server error')),
      ],
      verify: (_) {
        verifyNever(() => mockAuthSessionBloc.add(any()));
      },
    );

    test('emits a ShowErrorSnackbar presentation event carrying the failure '
        'message on failure', () async {
      const failure = ServerFailure('server error');
      when(
        () => mockLoginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenReturn(TaskEither.left(failure));

      final cubit = LoginCubit(mockLoginUseCase, mockAuthSessionBloc);
      final presentationEvents = <LoginPresentationEvent>[];
      final subscription = cubit.presentation.listen(presentationEvents.add);

      await cubit.submit(email: email, password: password);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await cubit.close();

      expect(presentationEvents, [
        LoginPresentationEvent.showErrorSnackbar(failure.message),
      ]);
    });

    test('emits no presentation event on success', () async {
      when(
        () => mockLoginUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenReturn(TaskEither.right(user));

      final cubit = LoginCubit(mockLoginUseCase, mockAuthSessionBloc);
      final presentationEvents = <LoginPresentationEvent>[];
      final subscription = cubit.presentation.listen(presentationEvents.add);

      await cubit.submit(email: email, password: password);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await cubit.close();

      expect(presentationEvents, isEmpty);
    });
  });
}
