import 'package:flutter/material.dart';
import 'package:olcerim/app/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: brightness == Brightness.light
          ? AppColors.primary
          : const Color(0xFFB9C3FF),
      primaryContainer: brightness == Brightness.light
          ? AppColors.primaryContainer
          : const Color(0xFF343A73),
      secondary: brightness == Brightness.light
          ? AppColors.secondary
          : const Color(0xFFBCC7D7),
      error: brightness == Brightness.light
          ? AppColors.error
          : const Color(0xFFFFB4AB),
    );

    final textTheme = ThemeData(brightness: brightness).textTheme.copyWith(
          displaySmall: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          headlineLarge: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(height: 80),
    );
  }
}
