import 'package:flutter_fundament/bootstrap.dart';
import 'package:flutter_fundament/core/config/env_prod.dart';

Future<void> main() async {
  await bootstrap(const EnvProd());
}
