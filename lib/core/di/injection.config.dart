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
import 'package:injectable/injectable.dart' as _i526;

import '../config/env.dart' as _i754;
import '../config/env_dev.dart' as _i819;
import '../config/env_prod.dart' as _i644;
import '../config/env_staging.dart' as _i537;
import '../network/auth_interceptor.dart' as _i908;
import '../network/dio_client.dart' as _i667;
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
    gh.lazySingleton<_i619.SecureStorage>(() => _i619.SecureStorage());
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
    gh.lazySingleton<_i754.Env>(
      () => const _i644.EnvProd(),
      registerFor: {_prod},
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(gh<_i754.Env>(), gh<_i908.AuthInterceptor>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i667.NetworkModule {}
