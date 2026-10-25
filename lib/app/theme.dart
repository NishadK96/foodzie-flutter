import 'package:flutter/material.dart';

abstract final class FoodzyColors {
  static const background = Color(0xFFFAF8F5);
  static const surface = Colors.white;
  static const sidebar = Color(0xFF1E2227);
  static const primary = Color(0xFFD32027);
  static const primaryDark = Color(0xFFB91C23);
  static const text = Color(0xFF19212B);
  static const muted = Color(0xFF68717D);
  static const border = Color(0xFFE9E5E0);
  static const selected = Color(0xFFFCEBE8);
  static const positive = Color(0xFF159447);
  static const inset = Color(0xFFF7F5F2);
}

abstract final class FoodzyTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: FoodzyColors.primary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: FoodzyColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: FoodzyColors.primary,
        surface: FoodzyColors.surface,
        onSurface: FoodzyColors.text,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FoodzyColors.text,
        displayColor: FoodzyColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FoodzyColors.background,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FoodzyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: FoodzyColors.border),
        ),
      ),
      dividerColor: FoodzyColors.border,
    );
  }
}
