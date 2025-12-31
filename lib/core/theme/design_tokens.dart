import 'package:flutter/material.dart';

class DesignTokens {
  static const spacing2 = 8.0;
  static const spacing3 = 12.0;
  static const spacing4 = 16.0;
  static const spacing5 = 20.0;
  static const spacing6 = 24.0;

  static const radiusSmall = 12.0;
  static const radiusMedium = 18.0;
  static const radiusLarge = 24.0;

  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);

  static const elevation = 12.0;
  static const glassColor = Color.fromARGB(150, 17, 29, 39);
  static const gradient = LinearGradient(
    colors: [Color(0xFF0B1824), Color(0xFF0E2233), Color(0xFF0D1A29)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
