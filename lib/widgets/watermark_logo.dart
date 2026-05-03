// lib/widgets/watermark_logo.dart
//
// Decorative center watermark shown between groups of menu items.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class WatermarkLogo extends StatelessWidget {
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final String? overrideText;

  const WatermarkLogo({
    super.key,
    required this.catTheme,
    required this.theme,
    this.overrideText,
  });

  @override
  Widget build(BuildContext context) {
    final text = overrideText ?? catTheme.label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              catTheme.primary.withOpacity(0.25),
              catTheme.accent.withOpacity(0.35),
              catTheme.primary.withOpacity(0.25),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            text.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              height: 1.0,
              color: theme.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
