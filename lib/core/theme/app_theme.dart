import 'package:flutter/material.dart';

/// The app's shared [ThemeData] definitions.
abstract final class AppTheme {
  /// The default light theme.
  static ThemeData get light =>
      ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true);
}
