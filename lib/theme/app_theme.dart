import 'package:flutter/material.dart';
import 'package:pulguinha/theme/app_colors.dart';

class AppTheme {
  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        bg: AppColors.bg,
        surface: AppColors.card,
        surfaceVariant: AppColors.card2,
        onSurface: AppColors.white,
        border: AppColors.border,
        hint: AppColors.grayDim,
      );

  static ThemeData get light => _base(
        brightness: Brightness.light,
        bg: AppColorsLight.bg,
        surface: AppColorsLight.card,
        surfaceVariant: AppColorsLight.card2,
        onSurface: AppColorsLight.textPrimary,
        border: AppColorsLight.border,
        hint: AppColorsLight.grayDim,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceVariant,
    required Color onSurface,
    required Color border,
    required Color hint,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.neon,
        onPrimary: const Color(0xFF111111),
        secondary: AppColors.neonDim,
        onSecondary: const Color(0xFF111111),
        error: AppColors.red,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      cardColor: surface,
      dividerColor: border,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.neon;
          return isDark ? AppColors.gray : AppColorsLight.gray;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neon),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: TextStyle(color: hint),
      ),
      fontFamily: 'Roboto',
    );
  }
}
