// lib/core/theme/app_theme.dart:App Theme and Colors
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary - Gold theme
  static const primaryGold = Color(0xFFD4AF37);
  static const primaryGoldLight = Color(0xFFE8D090);
  static const primaryGoldDark = Color(0xFFA8892A);

  // Secondary - Silver
  static const secondarySilver = Color(0xFFC0C0C0);

  // Accent - Platinum
  static const accentPlatinum = Color(0xFF00D4FF);

  // Backgrounds
  static const backgroundDark = Color(0xFF1A1A1A);
  static const backgroundCard = Color(0xFF2A2A2A);
  static const backgroundLight = Color(0xFFF5F5F5);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textDark = Color(0xFF1A1A1A);

  // Status
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFC107);
  static const error = Color(0xFFF44336);

  // Gain/Loss
  static const gainGreen = Color(0xFF00C853);
  static const lossRed = Color(0xFFFF1744);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryGold,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGold,
        secondary: AppColors.secondarySilver,
        surface: AppColors.backgroundCard,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineLarge: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
