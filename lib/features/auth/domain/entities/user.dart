import 'package:equatable/equatable.dart';

/// A logged-in user's identity, as understood by the domain layer.
class User extends Equatable {
  /// Creates a [User] with the given [id], [email], and [name].
  const User({required this.id, required this.email, required this.name});

  /// The user's unique identifier.
  final String id;

  /// The user's email address.
  final String email;

  /// The user's display name.
  final String name;

  @override
  List<Object?> get props => [id, email, name];
}
