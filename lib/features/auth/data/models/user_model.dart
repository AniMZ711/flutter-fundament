import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Wire/JSON shape of a user, as returned by the auth API.
@freezed
abstract class UserModel with _$UserModel {
  /// Creates a [UserModel].
  const factory UserModel({
    required String id,
    required String email,
    required String name,
  }) = _UserModel;

  /// Deserializes a [UserModel] from JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
