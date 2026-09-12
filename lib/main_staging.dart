import 'package:flutter_fundament/bootstrap.dart';
import 'package:flutter_fundament/core/config/env_staging.dart';

Future<void> main() async {
  await bootstrap(const EnvStaging());
}
