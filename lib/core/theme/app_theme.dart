import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade100,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D1AC),
          brightness: Brightness.dark,
          surface: const Color(0xFF0A0E16),
          background: const Color(0xFF04070D),
        ),
        scaffoldBackgroundColor: const Color(0xFF04070D),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      );
}
