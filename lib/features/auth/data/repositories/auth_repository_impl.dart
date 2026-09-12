import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_fundament/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_fundament/features/auth/data/mappers/user_mapper.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_fundament/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

/// [AuthRepository] implementation: data sources throw, this catches via
/// [TaskEither.tryCatch] and maps to a typed [Failure].
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl].
  const AuthRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._userMapper,
  );

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final UserMapper _userMapper;

  @override
  TaskEither<Failure, User> login({
    required String email,
    required String password,
  }) {
    return TaskEither.tryCatch(() async {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      await _localDataSource.cacheSession(
        token: response.token,
        user: response.user,
      );
      return _userMapper.map(response.user);
    }, _mapExceptionToFailure);
  }

  @override
  TaskEither<Failure, Unit> logout() {
    return TaskEither.tryCatch(() async {
      await _localDataSource.clearSession();
      return unit;
    }, _mapExceptionToFailure);
  }

  @override
  TaskEither<Failure, Option<User>> getCurrentUser() {
    return TaskEither.tryCatch(() async {
      final cached = await _localDataSource.getCachedUser();
      if (cached == null) {
        return const None();
      }
      return Some(_userMapper.map(cached));
    }, _mapExceptionToFailure);
  }

  /// Translates an exception thrown by a data source into a typed [Failure].
  Failure _mapExceptionToFailure(Object error, StackTrace stackTrace) {
    return switch (error) {
      ServerException(:final message) => ServerFailure(message),
      NetworkException(:final message) => NetworkFailure(message),
      CacheException(:final message) => CacheFailure(message),
      _ => UnexpectedFailure(error.toString()),
    };
  }
}
