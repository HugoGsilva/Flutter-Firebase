import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color roxoLenda = Color(0xFF5E35B1);
  static const Color douradoLenda = Color(0xFFFFB300);

  static const Color ouro = Color(0xFFFFCA28);
  static const Color prata = Color(0xFFB0BEC5);
  static const Color bronze = Color(0xFFBC8A5F);

  static const Color estrela = Color(0xFFFFA000);

  static Color corDaPosicao(int posicao, ColorScheme scheme) {
    return switch (posicao) {
      1 => ouro,
      2 => prata,
      3 => bronze,
      _ => scheme.surfaceContainerHighest,
    };
  }

  static Color textoDaPosicao(int posicao, ColorScheme scheme) {
    return posicao <= 3 ? Colors.black87 : scheme.onSurfaceVariant;
  }
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.roxoLenda,
      secondary: AppColors.douradoLenda,
      brightness: brightness,
    );

    final bordaArredondada = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: bordaArredondada,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: bordaArredondada,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
