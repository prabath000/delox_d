import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Premium Lavender Palette
  static const Color lavender = Color(0xFFB5B8F9);
  static const Color background = Color(0xFFF0F2FF);
  static const Color indigo = Color(0xFF5B67C9);
  static const Color peach = Color(0xFFF4CEB4);
  static const Color mint = Color(0xFFD1E9F6);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color primary = indigo;
  static const Color accent = lavender;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      primaryColor: AppColors.indigo,
      backgroundColor: AppColors.background,
      cardColor: AppColors.cardBg,
      textColor: AppColors.textMain,
      secondaryTextColor: AppColors.textSecondary,
      borderColor: AppColors.border,
    );
  }

  static ThemeData get darkTheme {
    // For now, we'll use a deep indigo version for dark mode to stay on brand
    return _buildTheme(
      brightness: Brightness.dark,
      primaryColor: AppColors.lavender,
      backgroundColor: const Color(0xFF1A1C2E),
      cardColor: const Color(0xFF252841),
      textColor: Colors.white,
      secondaryTextColor: Colors.white70,
      borderColor: Colors.white12,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color backgroundColor,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: primaryColor,
              secondary: AppColors.lavender,
              surface: cardColor,
            )
          : ColorScheme.light(
              primary: primaryColor,
              secondary: AppColors.indigo,
              surface: cardColor,
            ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: secondaryTextColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        hintStyle: GoogleFonts.outfit(
          color: secondaryTextColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
