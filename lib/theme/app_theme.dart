// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surfaceElevated = Color(0xFF1C1C28);
  static const Color gold = Color(0xFFE8B84B);
  static const Color goldLight = Color(0xFFF5D07A);
  static const Color goldDim = Color(0xFF8A6E2A);
  static const Color white = Color(0xFFF5F5F0);
  static const Color whiteDim = Color(0xFFB0AFA8);
  static const Color vegGreen = Color(0xFF2ECC71);
  static const Color nonVegRed = Color(0xFFE74C3C);
  static const Color starAmber = Color(0xFFFFB300);
  static const Color accentBlue = Color(0xFF3D9CF5);
  static const Color cardBorder = Color(0xFF2A2A38);

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        secondary: goldLight,
        surface: surface,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          color: white, fontWeight: FontWeight.w700, letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: white, fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.nunito(
          color: white, fontWeight: FontWeight.w800, letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.nunito(color: white, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.nunito(color: whiteDim, fontWeight: FontWeight.w400),
      ),
    );
  }

  static TextStyle playfair({
    double fontSize = 16,
    FontWeight weight = FontWeight.w700,
    Color color = white,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle nunito({
    double fontSize = 14,
    FontWeight weight = FontWeight.w500,
    Color color = white,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static Map<String, CategoryTheme> categoryThemes = {
    'veg': CategoryTheme(
      primary: vegGreen,
      secondary: const Color(0xFF1A5C35),
      gradient: [const Color(0xFF0D2E1A), const Color(0xFF1A5C35)],
      accent: const Color(0xFF7DEBA0),
      icon: '🌿',
    ),
    'non_veg': CategoryTheme(
      primary: nonVegRed,
      secondary: const Color(0xFF6B1C1C),
      gradient: [const Color(0xFF2E0D0D), const Color(0xFF6B1C1C)],
      accent: const Color(0xFFFF8A7A),
      icon: '🍖',
    ),
    'todays_star': CategoryTheme(
      primary: starAmber,
      secondary: const Color(0xFF6B4A0D),
      gradient: [const Color(0xFF2E1F0A), const Color(0xFF6B4A0D)],
      accent: const Color(0xFFFFE066),
      icon: '⭐',
    ),
    'beverages': CategoryTheme(
      primary: accentBlue,
      secondary: const Color(0xFF0D2E6B),
      gradient: [const Color(0xFF0A142E), const Color(0xFF0D2E6B)],
      accent: const Color(0xFF7AB8FF),
      icon: '🥤',
    ),
    'desserts': CategoryTheme(
      primary: const Color(0xFFE86DB5),
      secondary: const Color(0xFF6B1C55),
      gradient: [const Color(0xFF2E0A22), const Color(0xFF6B1C55)],
      accent: const Color(0xFFFFADE5),
      icon: '🍰',
    ),
  };
}

class CategoryTheme {
  final Color primary;
  final Color secondary;
  final List<Color> gradient;
  final Color accent;
  final String icon;

  const CategoryTheme({
    required this.primary,
    required this.secondary,
    required this.gradient,
    required this.accent,
    required this.icon,
  });
}
