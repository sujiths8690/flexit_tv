// lib/theme/app_theme.dart
//
// Theme system for the TV menu board.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum MenuThemeType {
  light,
  dark,
  warm,
  neon,
  mint,
  ocean,
  sunrise,
  royal,
  paper,
  graphite,
}

class TvMenuThemeData {
  final Color background;
  final Color backgroundAccent;
  final Color glowColor;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;
  final Color textureColor;
  final Color headerBg;
  final bool isDark;
  final bool animated;

  const TvMenuThemeData({
    required this.background,
    required this.backgroundAccent,
    required this.glowColor,
    required this.primaryText,
    required this.secondaryText,
    required this.divider,
    required this.textureColor,
    required this.headerBg,
    required this.isDark,
    this.animated = false,
  });
}

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color cardBorder = Color(0x22FFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteDim = Color(0x99FFFFFF);
  static const Color vegGreen = Color(0xFF4CAF50);
  static const Color nonVegRed = Color(0xFFB33A2B);
  static const Color gold = Color(0xFFD4A853);
  static const Color goldLight = Color(0xFFE8C070);
  static const Color goldDim = Color(0xFF8A6E2A);
  static const Color starAmber = Color(0xFFFFB300);

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
          color: white,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: white,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.nunito(
          color: white,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: GoogleFonts.nunito(
          color: white,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.nunito(
          color: whiteDim,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  static TvMenuThemeData menuTheme(MenuThemeType type) {
    switch (type) {
      case MenuThemeType.light:
        return const TvMenuThemeData(
          background: Color(0xFFF4F0EA),
          backgroundAccent: Color(0xFFE8D8BE),
          glowColor: Color(0x26C9902E),
          primaryText: Color(0xFF1A1208),
          secondaryText: Color(0xFF6B6152),
          divider: Color(0x22000000),
          textureColor: Color(0x0A000000),
          headerBg: Color(0xFFF4F0EA),
          isDark: false,
        );
      case MenuThemeType.dark:
        return const TvMenuThemeData(
          background: Color(0xFF0D0D0D),
          backgroundAccent: Color(0xFF252018),
          glowColor: Color(0x22D4A853),
          primaryText: Color(0xFFF5F0E8),
          secondaryText: Color(0xFF9A8F80),
          divider: Color(0x22FFFFFF),
          textureColor: Color(0x08FFFFFF),
          headerBg: Color(0xFF111111),
          isDark: true,
        );
      case MenuThemeType.warm:
        return const TvMenuThemeData(
          background: Color(0xFF2A1A0E),
          backgroundAccent: Color(0xFF4A2612),
          glowColor: Color(0x30F5A64A),
          primaryText: Color(0xFFF5E6C8),
          secondaryText: Color(0xFFB8956A),
          divider: Color(0x33F5C88A),
          textureColor: Color(0x0AF5C88A),
          headerBg: Color(0xFF1E1208),
          isDark: true,
        );
      case MenuThemeType.neon:
        return const TvMenuThemeData(
          background: Color(0xFF060612),
          backgroundAccent: Color(0xFF101034),
          glowColor: Color(0x4400FFCC),
          primaryText: Color(0xFFEEEEFF),
          secondaryText: Color(0xFF8888BB),
          divider: Color(0x2200FFCC),
          textureColor: Color(0x0600FFCC),
          headerBg: Color(0xFF08080F),
          isDark: true,
          animated: true,
        );
      case MenuThemeType.mint:
        return const TvMenuThemeData(
          background: Color(0xFFEFFBF3),
          backgroundAccent: Color(0xFFD6F2E4),
          glowColor: Color(0x3324B47E),
          primaryText: Color(0xFF10251B),
          secondaryText: Color(0xFF577064),
          divider: Color(0x1F0F5F42),
          textureColor: Color(0x100F5F42),
          headerBg: Color(0xFFE7F7EE),
          isDark: false,
          animated: true,
        );
      case MenuThemeType.ocean:
        return const TvMenuThemeData(
          background: Color(0xFF061923),
          backgroundAccent: Color(0xFF0E3A4D),
          glowColor: Color(0x3D46C2FF),
          primaryText: Color(0xFFE9FAFF),
          secondaryText: Color(0xFF8AB8C8),
          divider: Color(0x2646C2FF),
          textureColor: Color(0x0D9DE7FF),
          headerBg: Color(0xFF08202B),
          isDark: true,
          animated: true,
        );
      case MenuThemeType.sunrise:
        return const TvMenuThemeData(
          background: Color(0xFFFFF6EC),
          backgroundAccent: Color(0xFFFFD7A8),
          glowColor: Color(0x3DEB6A5A),
          primaryText: Color(0xFF32170D),
          secondaryText: Color(0xFF8A5942),
          divider: Color(0x22A64B2A),
          textureColor: Color(0x0FA64B2A),
          headerBg: Color(0xFFFFEBDC),
          isDark: false,
          animated: true,
        );
      case MenuThemeType.royal:
        return const TvMenuThemeData(
          background: Color(0xFF150D2B),
          backgroundAccent: Color(0xFF321B63),
          glowColor: Color(0x40C6A7FF),
          primaryText: Color(0xFFF4EDFF),
          secondaryText: Color(0xFFB7A6D9),
          divider: Color(0x2EC6A7FF),
          textureColor: Color(0x0FC6A7FF),
          headerBg: Color(0xFF1C1238),
          isDark: true,
          animated: true,
        );
      case MenuThemeType.paper:
        return const TvMenuThemeData(
          background: Color(0xFFFAF7EF),
          backgroundAccent: Color(0xFFE9DFC9),
          glowColor: Color(0x1F9D6B2F),
          primaryText: Color(0xFF2B2116),
          secondaryText: Color(0xFF766956),
          divider: Color(0x24000000),
          textureColor: Color(0x12000000),
          headerBg: Color(0xFFF4ECDD),
          isDark: false,
        );
      case MenuThemeType.graphite:
        return const TvMenuThemeData(
          background: Color(0xFF121416),
          backgroundAccent: Color(0xFF262B2F),
          glowColor: Color(0x2C98A7B5),
          primaryText: Color(0xFFF1F4F5),
          secondaryText: Color(0xFFA5ADB2),
          divider: Color(0x26FFFFFF),
          textureColor: Color(0x0CFFFFFF),
          headerBg: Color(0xFF171A1D),
          isDark: true,
        );
    }
  }

  static const Map<String, CategoryTheme> categoryThemes = {
    'all': CategoryTheme(
      primary: Color(0xFFD4A853),
      secondary: Color(0xFF8B6914),
      accent: Color(0xFFE8C070),
      gradient: [Color(0xFFD4A853), Color(0xFF8B6914)],
      icon: 'ALL',
      label: 'Menu',
    ),
    'veg': CategoryTheme(
      primary: Color(0xFF3DAA5C),
      secondary: Color(0xFF1A6B35),
      accent: Color(0xFF5DC97A),
      gradient: [Color(0xFF3DAA5C), Color(0xFF1A6B35)],
      icon: 'VEG',
      label: 'Veg',
    ),
    'nonVeg': CategoryTheme(
      primary: Color(0xFFB33A2B),
      secondary: Color(0xFF6F1F17),
      accent: Color(0xFFE06145),
      gradient: [Color(0xFFB33A2B), Color(0xFF6F1F17)],
      icon: 'NV',
      label: 'Non Veg',
    ),
    'non_veg': CategoryTheme(
      primary: Color(0xFFB33A2B),
      secondary: Color(0xFF6F1F17),
      accent: Color(0xFFE06145),
      gradient: [Color(0xFFB33A2B), Color(0xFF6F1F17)],
      icon: 'NV',
      label: 'Non Veg',
    ),
    'todaysStar': CategoryTheme(
      primary: Color(0xFFD4A820),
      secondary: Color(0xFF7A5C00),
      accent: Color(0xFFFFD700),
      gradient: [Color(0xFFD4A820), Color(0xFF7A5C00)],
      icon: 'STAR',
      label: "Today's Star",
    ),
    'todays_star': CategoryTheme(
      primary: Color(0xFFD4A820),
      secondary: Color(0xFF7A5C00),
      accent: Color(0xFFFFD700),
      gradient: [Color(0xFFD4A820), Color(0xFF7A5C00)],
      icon: 'STAR',
      label: "Today's Star",
    ),
    'beverages': CategoryTheme(
      primary: Color(0xFF2A7DD4),
      secondary: Color(0xFF0D3D70),
      accent: Color(0xFF5AAEFF),
      gradient: [Color(0xFF2A7DD4), Color(0xFF0D3D70)],
      icon: 'DRINK',
      label: 'Beverages',
    ),
    'desserts': CategoryTheme(
      primary: Color(0xFFD45A9A),
      secondary: Color(0xFF7A1A52),
      accent: Color(0xFFFF8FCE),
      gradient: [Color(0xFFD45A9A), Color(0xFF7A1A52)],
      icon: 'SWEET',
      label: 'Desserts',
    ),
  };

  static CategoryTheme colorizedCategoryTheme(
    CategoryTheme base,
    String? colorKey,
  ) {
    final colors = _accentPalette(colorKey);
    if (colors == null) return base;

    return CategoryTheme(
      primary: colors[0],
      secondary: colors[1],
      accent: colors[2],
      gradient: [colors[0], colors[1]],
      icon: base.icon,
      label: base.label,
    );
  }

  static List<Color>? _accentPalette(String? colorKey) {
    switch (colorKey) {
      case 'green':
        return const [Color(0xFF37B26C), Color(0xFF136D42), Color(0xFF65D88F)];
      case 'blue':
        return const [Color(0xFF358CFF), Color(0xFF123E82), Color(0xFF76B8FF)];
      case 'rose':
        return const [Color(0xFFE85286), Color(0xFF832243), Color(0xFFFF8CB4)];
      case 'purple':
        return const [Color(0xFF8E5DFF), Color(0xFF432081), Color(0xFFBDA1FF)];
      case 'orange':
        return const [Color(0xFFFF8A3D), Color(0xFF8B3D13), Color(0xFFFFB16F)];
      case 'teal':
        return const [Color(0xFF21BFAE), Color(0xFF0C675F), Color(0xFF6FE3D7)];
      case 'slate':
        return const [Color(0xFF8898A8), Color(0xFF3E4B57), Color(0xFFC3CED8)];
      case 'gold':
        return null;
      default:
        return null;
    }
  }
}

class CategoryTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final List<Color> gradient;
  final String icon;
  final String label;

  const CategoryTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.icon,
    required this.label,
  });
}
