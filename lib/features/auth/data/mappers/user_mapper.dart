import 'package:flutter_fundament/core/mapper/mapper.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:injectable/injectable.dart';

/// Maps a data-layer [UserModel] to a domain-layer [User].
@lazySingleton
class UserMapper extends Mapper<UserModel, User> {
  @override
  User map(UserModel input) {
    return User(id: input.id, email: input.email, name: input.name);
  }
}
