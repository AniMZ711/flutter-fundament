import 'package:flutter_fundament/core/error/failure.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_state.freezed.dart';

/// State for the login form, driven by `LoginCubit`.
@freezed
sealed class LoginState with _$LoginState {
  /// The form has not been submitted yet.
  const factory LoginState.initial() = LoginInitial;

  /// A login request is in flight.
  const factory LoginState.submitting() = LoginSubmitting;

  /// The login request succeeded, yielding the now-authenticated [user].
  const factory LoginState.success(User user) = LoginSuccess;

  /// The login request failed with [failure].
  const factory LoginState.failure(Failure failure) = LoginFailure;
}
