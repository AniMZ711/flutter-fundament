// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:go_router/go_router.dart' as _i583;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/datasources/auth_local_data_source.dart'
    as _i852;
import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/datasources/mock_auth_remote_data_source.dart'
    as _i297;
import '../../features/auth/data/mappers/user_mapper.dart' as _i84;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i17;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/presentation/bloc/auth_session_bloc.dart' as _i158;
import '../../features/auth/presentation/cubit/login_cubit.dart' as _i69;
import '../config/env.dart' as _i754;
import '../config/env_dev.dart' as _i819;
import '../config/env_prod.dart' as _i644;
import '../config/env_staging.dart' as _i537;
import '../network/auth_interceptor.dart' as _i908;
import '../network/dio_client.dart' as _i667;
import '../router/app_router.dart' as _i81;
import '../storage/secure_storage.dart' as _i619;

const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    final routerModule = _$RouterModule();
    gh.lazySingleton<_i619.SecureStorage>(() => _i619.SecureStorage());
    gh.lazySingleton<_i84.UserMapper>(() => _i84.UserMapper());
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => const _i297.MockAuthRemoteDataSource(),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i754.Env>(
      () => const _i819.EnvDev(),
      registerFor: {_dev},
    );
    gh.lazySingleton<_i754.Env>(
      () => const _i537.EnvStaging(),
      registerFor: {_staging},
    );
    gh.factory<_i908.AuthInterceptor>(
      () => _i908.AuthInterceptor(gh<_i619.SecureStorage>()),
    );
    gh.lazySingleton<_i852.AuthLocalDataSource>(
      () => _i852.AuthLocalDataSourceImpl(gh<_i619.SecureStorage>()),
    );
    gh.lazySingleton<_i754.Env>(
      () => const _i644.EnvProd(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(gh<_i754.Env>(), gh<_i908.AuthInterceptor>()),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(gh<_i361.Dio>()),
      registerFor: {_staging, _prod},
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        gh<_i107.AuthRemoteDataSource>(),
        gh<_i852.AuthLocalDataSource>(),
        gh<_i84.UserMapper>(),
      ),
    );
    gh.factory<_i17.GetCurrentUserUseCase>(
      () => _i17.GetCurrentUserUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i48.LogoutUseCase>(
      () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i158.AuthSessionBloc>(
      () => _i158.AuthSessionBloc(
        gh<_i17.GetCurrentUserUseCase>(),
        gh<_i48.LogoutUseCase>(),
      ),
    );
    gh.lazySingleton<_i583.GoRouter>(
      () => routerModule.appRouter(gh<_i158.AuthSessionBloc>()),
    );
    gh.factory<_i69.LoginCubit>(
      () => _i69.LoginCubit(
        gh<_i188.LoginUseCase>(),
        gh<_i158.AuthSessionBloc>(),
      ),
    );
    return this;
  }
}

class _$NetworkModule extends _i667.NetworkModule {}

class _$RouterModule extends _i81.RouterModule {}
