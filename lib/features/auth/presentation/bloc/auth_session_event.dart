import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session_event.freezed.dart';

/// Events driving `AuthSessionBloc`.
@freezed
sealed class AuthSessionEvent with _$AuthSessionEvent {
  /// Fired once on app start to check for an existing session.
  const factory AuthSessionEvent.appStarted() = AppStarted;

  /// Fired when a login succeeds, carrying the now-authenticated [User].
  const factory AuthSessionEvent.loggedIn(User user) = LoggedIn;

  /// Fired to end the current session.
  const factory AuthSessionEvent.loggedOut() = LoggedOut;
}
