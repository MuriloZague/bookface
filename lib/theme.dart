import 'package:flutter/material.dart';

/// Paleta e tema no estilo "rede social" (inspirado no Facebook).
class AppColors {
  static const Color primary = Color(0xFF1877F2); // azul principal
  static const Color primaryDark = Color(0xFF0B5FCC);
  static const Color background = Color(0xFFF0F2F5); // cinza claro do feed
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF050505);
  static const Color textSecondary = Color(0xFF65676B);
  static const Color field = Color(0xFFF5F6F7);
  static const Color border = Color(0xFFDDDFE2);
  static const Color success = Color(0xFF42B72A); // verde "criar conta"
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
