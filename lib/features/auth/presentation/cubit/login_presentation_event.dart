import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_presentation_event.freezed.dart';

/// One-shot side effects fired by `LoginCubit`.
///
/// There is deliberately no `NavigateToHome` variant: success-path
/// navigation happens automatically once `LoginCubit` dispatches
/// `AuthSessionEvent.loggedIn(user)` to `AuthSessionBloc`, which
/// `go_router`'s redirect reacts to — `LoginCubit` itself never navigates.
@freezed
sealed class LoginPresentationEvent with _$LoginPresentationEvent {
  /// Show a snackbar with [message] — the login-failure one-shot side effect.
  const factory LoginPresentationEvent.showErrorSnackbar(String message) =
      ShowErrorSnackbar;
}
