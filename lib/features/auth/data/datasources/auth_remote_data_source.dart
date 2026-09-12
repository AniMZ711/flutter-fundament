import 'package:dio/dio.dart';
import 'package:flutter_fundament/core/config/env.dart';
import 'package:flutter_fundament/core/network/exceptions.dart';
import 'package:flutter_fundament/features/auth/data/models/auth_response_model.dart';
import 'package:injectable/injectable.dart';

/// Auth operations that hit the remote API.
abstract interface class AuthRemoteDataSource {
  /// Authenticates with [email]/[password] against the API, returning the
  /// raw [AuthResponseModel] on success.
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });
}

/// [Dio]-backed implementation of [AuthRemoteDataSource].
@LazySingleton(as: AuthRemoteDataSource, env: [Flavor.staging, Flavor.prod])
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Creates an [AuthRemoteDataSourceImpl] backed by [_dio].
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw mapDioExceptionToDataException(e);
    }
  }
}
