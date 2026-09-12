import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_fundament/features/auth/data/mappers/user_mapper.dart';
import 'package:flutter_fundament/features/auth/data/models/auth_response_model.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:flutter_fundament/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _MockUserMapper extends Mock implements UserMapper {}

void main() {
  late _MockAuthRemoteDataSource mockRemoteDataSource;
  late _MockAuthLocalDataSource mockLocalDataSource;
  late _MockUserMapper mockUserMapper;
  late AuthRepositoryImpl repository;

  const email = 'test@example.com';
  const password = 'password123';
  const userModel = UserModel(id: '1', email: email, name: 'Test User');
  const user = User(id: '1', email: email, name: 'Test User');
  const authResponse = AuthResponseModel(token: 'a-token', user: userModel);

  setUpAll(() {
    registerFallbackValue(userModel);
  });

  setUp(() {
    mockRemoteDataSource = _MockAuthRemoteDataSource();
    mockLocalDataSource = _MockAuthLocalDataSource();
    mockUserMapper = _MockUserMapper();
    repository = AuthRepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
      mockUserMapper,
    );
  });

  group('login', () {
    test('returns Right(User) and caches the session on success', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => authResponse);
      when(
        () => mockLocalDataSource.cacheSession(
          token: any(named: 'token'),
          user: any(named: 'user'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockUserMapper.map(userModel)).thenReturn(user);

      final result = await repository
          .login(email: email, password: password)
          .run();

      expect(result, const Right<Failure, User>(user));
      verify(
        () => mockLocalDataSource.cacheSession(
          token: authResponse.token,
          user: authResponse.user,
        ),
      ).called(1);
    });

    test('returns Left(ServerFailure) when the remote data source throws '
        'ServerException', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const ServerException('server error'));

      final result = await repository
          .login(email: email, password: password)
          .run();

      expect(result, const Left<Failure, User>(ServerFailure('server error')));
    });

    test('returns Left(NetworkFailure) when the remote data source throws '
        'NetworkException', () async {
      when(
        () => mockRemoteDataSource.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const NetworkException('network error'));

      final result = await repository
          .login(email: email, password: password)
          .run();

      expect(
        result,
        const Left<Failure, User>(NetworkFailure('network error')),
      );
    });
  });

  group('logout', () {
    test('returns Right(unit) on success', () async {
      when(() => mockLocalDataSource.clearSession()).thenAnswer((_) async {});

      final result = await repository.logout().run();

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('returns Left(CacheFailure) when the local data source throws '
        'CacheException', () async {
      when(
        () => mockLocalDataSource.clearSession(),
      ).thenThrow(const CacheException('cache error'));

      final result = await repository.logout().run();

      expect(result, const Left<Failure, Unit>(CacheFailure('cache error')));
    });
  });

  group('getCurrentUser', () {
    test('returns Right(Some(User)) when a user is cached', () async {
      when(
        () => mockLocalDataSource.getCachedUser(),
      ).thenAnswer((_) async => userModel);
      when(() => mockUserMapper.map(userModel)).thenReturn(user);

      final result = await repository.getCurrentUser().run();

      expect(result, const Right<Failure, Option<User>>(Some(user)));
    });

    test('returns Right(None()) when no user is cached', () async {
      when(
        () => mockLocalDataSource.getCachedUser(),
      ).thenAnswer((_) async => null);

      final result = await repository.getCurrentUser().run();

      expect(result, const Right<Failure, Option<User>>(None()));
    });

    test('returns Left(CacheFailure) when the local data source throws '
        'CacheException', () async {
      when(
        () => mockLocalDataSource.getCachedUser(),
      ).thenThrow(const CacheException('cache error'));

      final result = await repository.getCurrentUser().run();

      expect(
        result,
        const Left<Failure, Option<User>>(CacheFailure('cache error')),
      );
    });
  });
}
