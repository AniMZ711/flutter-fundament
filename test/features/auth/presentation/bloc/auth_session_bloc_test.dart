import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetCurrentUserUseCase extends Mock
    implements GetCurrentUserUseCase {}

class _MockLogoutUseCase extends Mock implements LogoutUseCase {}

void main() {
  late _MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late _MockLogoutUseCase mockLogoutUseCase;

  const user = User(id: '1', email: 'test@example.com', name: 'Test User');

  setUp(() {
    mockGetCurrentUserUseCase = _MockGetCurrentUserUseCase();
    mockLogoutUseCase = _MockLogoutUseCase();
  });

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [authenticated] when AppStarted finds an existing session',
    setUp: () {
      when(
        () => mockGetCurrentUserUseCase(),
      ).thenReturn(TaskEither.right(some(user)));
    },
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.appStarted()),
    expect: () => [const AuthSessionState.authenticated(user)],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [unauthenticated] when AppStarted finds no session',
    setUp: () {
      when(
        () => mockGetCurrentUserUseCase(),
      ).thenReturn(TaskEither.right(const None()));
    },
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.appStarted()),
    expect: () => [const AuthSessionState.unauthenticated()],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [unauthenticated] when AppStarted fails to load the session',
    setUp: () {
      when(
        () => mockGetCurrentUserUseCase(),
      ).thenReturn(TaskEither.left(const CacheFailure('cache error')));
    },
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.appStarted()),
    expect: () => [const AuthSessionState.unauthenticated()],
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [authenticated] when LoggedIn is added',
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.loggedIn(user)),
    expect: () => [const AuthSessionState.authenticated(user)],
    verify: (_) {
      verifyNever(() => mockGetCurrentUserUseCase());
      verifyNever(() => mockLogoutUseCase());
    },
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [unauthenticated] and calls LogoutUseCase when LoggedOut is added',
    setUp: () {
      when(() => mockLogoutUseCase()).thenReturn(TaskEither.right(unit));
    },
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.loggedOut()),
    expect: () => [const AuthSessionState.unauthenticated()],
    verify: (_) {
      verify(() => mockLogoutUseCase()).called(1);
    },
  );

  blocTest<AuthSessionBloc, AuthSessionState>(
    'emits [unauthenticated] when LoggedOut is added and logout fails',
    setUp: () {
      when(
        () => mockLogoutUseCase(),
      ).thenReturn(TaskEither.left(const CacheFailure('cache error')));
    },
    build: () => AuthSessionBloc(mockGetCurrentUserUseCase, mockLogoutUseCase),
    act: (bloc) => bloc.add(const AuthSessionEvent.loggedOut()),
    expect: () => [const AuthSessionState.unauthenticated()],
  );
}
