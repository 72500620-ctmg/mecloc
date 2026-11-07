import 'package:flutter/material.dart';

class AppRadii {
  static const card = 18.0;
  static const floating = 30.0;
  static const sheet = 28.0;
}

class AppColors {
  // Cores de identidade da marca Mecloc
  static const forest = Color(0xFF13453C);
  static const forestDark = Color(0xFF0C2E28);
  static const leaf = Color(0xFFA5D625);
  static const leafGlow = Color(0xFFBCE83A);
  static const ink = Color(0xFF141E1C);
  static const paper = Color(0xFFF6F8F5);
  static const muted = Color(0xFF6B7874);
  static const line = Color(0xFFE2E8E2);

  // Acentos de interface
  static const electricBlue = Color(0xFF007AFF);
  static const amberGold = Color(0xFFFFB300);
  static const coralRed = Color(0xFFFF3B30);

  // Cores de superfícies escuras
  static const darkBackground = Color(0xFF101715);
  static const darkSurface = Color(0xFF1A2421);
  static const darkLine = Color(0xFF293633);

  // Cores Liquid Glass
  static Color glassBackgroundLight = Colors.white.withValues(alpha: 0.82);
  static Color glassBackgroundDark =
      const Color(0xFF1A2421).withValues(alpha: 0.82);

  static Color glassBorderLight = Colors.white.withValues(alpha: 0.65);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.12);
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.forest,
      brightness: Brightness.light,
      primary: AppColors.forest,
      secondary: AppColors.leaf,
      surface: Colors.white,
      error: AppColors.coralRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.dark,
      primary: AppColors.leaf,
      secondary: AppColors.leafGlow,
      surface: AppColors.darkSurface,
      error: AppColors.coralRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: const BorderSide(color: AppColors.leaf, width: 1.8),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.darkLine),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.leaf,
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
