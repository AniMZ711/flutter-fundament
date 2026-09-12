import 'package:equatable/equatable.dart';

/// Base type for every recoverable error that crosses a repository
/// boundary. `message` is developer/log-facing; presentation layers map
/// a [Failure] to user-facing copy per feature.
sealed class Failure extends Equatable {
  /// Creates a [Failure] carrying a developer/log-facing [message].
  const Failure(this.message);

  /// Developer/log-facing description of what went wrong.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The server responded, but with an error (4xx/5xx, malformed body, ...).
class ServerFailure extends Failure {
  /// Creates a [ServerFailure] with the given [message].
  const ServerFailure(super.message);
}

/// Reading/writing/clearing cached or securely-stored data failed.
class CacheFailure extends Failure {
  /// Creates a [CacheFailure] with the given [message].
  const CacheFailure(super.message);
}

/// The request never reached a server (no connection, timeout, DNS, ...).
class NetworkFailure extends Failure {
  /// Creates a [NetworkFailure] with the given [message].
  const NetworkFailure(super.message);
}

/// User-supplied input failed validation before a request was made.
class ValidationFailure extends Failure {
  /// Creates a [ValidationFailure] with the given [message].
  const ValidationFailure(super.message);
}

/// A failure that doesn't fit any other [Failure] subtype.
class UnexpectedFailure extends Failure {
  /// Creates an [UnexpectedFailure] with the given [message].
  const UnexpectedFailure(super.message);
}
