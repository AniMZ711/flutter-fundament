import 'package:flutter_fundament/features/auth/data/mappers/user_mapper.dart';
import 'package:flutter_fundament/features/auth/data/models/user_model.dart';
import 'package:flutter_fundament/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserMapper mapper;

  setUp(() {
    mapper = UserMapper();
  });

  test('maps a UserModel to the equivalent User', () {
    const model = UserModel(
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
    );

    final result = mapper.map(model);

    expect(
      result,
      const User(id: '1', email: 'test@example.com', name: 'Test User'),
    );
  });
}
