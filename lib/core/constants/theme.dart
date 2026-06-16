import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF161B26);
  static const Color surfaceLight = Color(0xFF222B3C);
  
  static const Color accentBlue = Color(0xFF2F80ED);
  static const Color accentCyan = Color(0xFF00F2FE);
  static const Color accentNeonGreen = Color(0xFF39FF14);
  static const Color errorRed = Color(0xFFEB5757);
  static const Color textPrimary = Color(0xFFF2F2F2);
  static const Color textSecondary = Color(0xFF828282);

  // Glassmorphism Values
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x26FFFFFF);     // 15% white border
  static const double glassBlur = 16.0;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentBlue, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentBlue,
      cardColor: surface,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentBlue,
        inactiveTrackColor: surfaceLight,
        thumbColor: textPrimary,
        overlayColor: accentBlue.withOpacity(0.2),
        trackHeight: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
      ),
    );
  }
}
