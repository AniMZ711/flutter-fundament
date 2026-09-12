import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_model.freezed.dart';
part 'auth_response_model.g.dart';

/// Wire/JSON shape of a successful login response: a session [token] and
/// the [user] it belongs to.
@freezed
abstract class AuthResponseModel with _$AuthResponseModel {
  /// Creates an [AuthResponseModel].
  const factory AuthResponseModel({
    required String token,
    required UserModel user,
  }) = _AuthResponseModel;

  /// Deserializes an [AuthResponseModel] from JSON.
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseModelFromJson(json);
}
