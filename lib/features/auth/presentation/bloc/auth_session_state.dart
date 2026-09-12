import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session_state.freezed.dart';

/// The app-wide authentication session state.
@freezed
sealed class AuthSessionState with _$AuthSessionState {
  /// Not yet determined whether a session exists (shown as `/splash`).
  const factory AuthSessionState.unknown() = AuthSessionUnknown;

  /// A session exists, for the given [user].
  const factory AuthSessionState.authenticated(User user) =
      AuthSessionAuthenticated;

  /// No session exists.
  const factory AuthSessionState.unauthenticated() = AuthSessionUnauthenticated;
}
