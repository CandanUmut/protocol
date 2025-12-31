import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade100,
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        textTheme: _textTheme(Brightness.light),
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
        textTheme: _textTheme(Brightness.dark),
        cardTheme: CardTheme(
          color: DesignTokens.glassColor,
          elevation: DesignTokens.elevation,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
        ),
      );

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? Typography.whiteMountainView : Typography.blackMountainView;
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(letterSpacing: -0.5, fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(letterSpacing: -0.25, fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
    );
  }
}
