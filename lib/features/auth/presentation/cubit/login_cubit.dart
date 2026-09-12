import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fundament/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:flutter_fundament/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_presentation_event.dart';
import 'package:flutter_fundament/features/auth/presentation/cubit/login_state.dart';
import 'package:injectable/injectable.dart';

/// Screen-scoped state for the login form. A new instance is created per
/// screen (registered `@injectable`, i.e. a DI factory) — unlike
/// `AuthSessionBloc`, which is a deliberate app-wide singleton.
@injectable
class LoginCubit extends Cubit<LoginState>
    with BlocPresentationMixin<LoginState, LoginPresentationEvent> {
  /// Creates a [LoginCubit].
  LoginCubit(this._loginUseCase, this._authSessionBloc)
    : super(const LoginState.initial());

  final LoginUseCase _loginUseCase;
  final AuthSessionBloc _authSessionBloc;

  /// Attempts to log in with [email]/[password].
  Future<void> submit({required String email, required String password}) async {
    emit(const LoginState.submitting());
    final result = await _loginUseCase(email: email, password: password).run();
    result.match(
      (failure) {
        emit(LoginState.failure(failure));
        emitPresentation(
          LoginPresentationEvent.showErrorSnackbar(failure.message),
        );
      },
      (user) {
        emit(LoginState.success(user));
        _authSessionBloc.add(AuthSessionEvent.loggedIn(user));
      },
    );
  }
}
