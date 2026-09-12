import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:injectable/injectable.dart';

/// App-wide authentication session state, driving `go_router`'s redirect
/// logic (see Phase 4). Unlike every other Cubit/Bloc in this base (which
/// are screen-scoped `@injectable` factories), this Bloc is deliberately a
/// `@lazySingleton`: it must persist for the app's entire lifetime, since
/// the router holds a single long-lived subscription to its state stream.
@lazySingleton
class AuthSessionBloc extends Bloc<AuthSessionEvent, AuthSessionState> {
  /// Creates an [AuthSessionBloc], starting in [AuthSessionState.unknown]
  /// until [AuthSessionEvent.appStarted] resolves.
  AuthSessionBloc(this._getCurrentUserUseCase, this._logoutUseCase)
    : super(const AuthSessionState.unknown()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  @override
  void onChange(Change<AuthSessionState> change) {
    super.onChange(change);
    developer.log(
      '${change.currentState} -> ${change.nextState}',
      name: 'AuthSessionBloc',
    );
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthSessionState> emit,
  ) async {
    final result = await _getCurrentUserUseCase().run();
    result.match(
      (failure) => emit(const AuthSessionState.unauthenticated()),
      (maybeUser) => maybeUser.match(
        () => emit(const AuthSessionState.unauthenticated()),
        (user) => emit(AuthSessionState.authenticated(user)),
      ),
    );
  }

  Future<void> _onLoggedIn(
    LoggedIn event,
    Emitter<AuthSessionState> emit,
  ) async {
    emit(AuthSessionState.authenticated(event.user));
  }

  Future<void> _onLoggedOut(
    LoggedOut event,
    Emitter<AuthSessionState> emit,
  ) async {
    await _logoutUseCase().run();
    emit(const AuthSessionState.unauthenticated());
  }
}
