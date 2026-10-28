import 'package:flutter/material.dart';

/// Light-only theme: warm cream, sunrise gold and sage green.
class AppTheme {
  static const cream = Color(0xFFFFF9EE);
  static const sage = Color(0xFF7FA38A);
  static const gold = Color(0xFFE9B949);
  static const peach = Color(0xFFF6C9A8);
  static const ink = Color(0xFF3B3A36);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.light,
      surface: cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sage,
        foregroundColor: Colors.white,
      ),
    );
  }
}

