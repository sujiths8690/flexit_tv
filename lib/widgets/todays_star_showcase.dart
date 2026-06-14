import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _localizedTodaysStar(String language) =>
    _isMalayalam(language) ? 'ഇന്നത്തെ താരം' : "Today's Star";

const _kPosterRed = Color(0xFFCC1A1A);
const _kPosterRedDark = Color(0xFF9E0E0E);
const _kPosterRedLight = Color(0xFFE03030);
const _kPosterYellow = Color(0xFFF5A800);
const _kPosterYellowLight = Color(0xFFFFC82E);
const _kPosterOrange = Color(0xFFE8711A);

class TodaysStarShowcase extends StatelessWidget {
  final List<MenuItem> items;
  final int pageIndex;
  final Size screenSize;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final bool showPrice;
  final bool showProductImage;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final String displayLanguage;

  const TodaysStarShowcase({
    super.key,
    required this.items,
    required this.pageIndex,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
    required this.showPrice,
    required this.showProductImage,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.displayLanguage,
  });

  // Unchanged: one item per page
  int get _itemsPerPage => 1;

  @override
  Widget build(BuildContext context) {
    // ── Pagination logic — untouched ──────────────────────────────────────
    final pageCount =
        (items.length / _itemsPerPage).ceil().clamp(1, items.length);
    final safePageIndex = pageIndex % pageCount;
    final start = safePageIndex * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, items.length);
    final pageItems = items.sublist(start, end);
    final longestName = pageItems.fold<int>(
      8,
      (value, item) => max(value, item.name.length),
    );
    final nameSize = ((screenSize.width * 0.040) * nameFontScale)
        .clamp(28.0, longestName > 20 ? 58.0 : 72.0);
    final priceSize =
        ((screenSize.width * 0.032) * priceFontScale).clamp(24.0, 54.0);

    final productKey = ValueKey(
      'todays-star-products-$safePageIndex-${pageItems.map((item) => item.id).join('-')}',
    );
    // ─────────────────────────────────────────────────────────────────────

    // How tall the red (top) section is — roughly 42 % of screen height
    const redFraction = 0.46;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Two-tone poster background ─────────────────────────────────
        const Positioned.fill(child: _PosterBackground()),

        // ── 2. Decorative garnish layer (dots, triangles, squiggles) ──────
        Positioned.fill(
          child: _PosterGarnishLayer(screenSize: screenSize),
        ),

        // ── 3. Thin border frame ──────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsets.all(
                (screenSize.width * 0.018).clamp(10.0, 22.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(
                    (screenSize.width * 0.012).clamp(6.0, 18.0),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── 4. Content: title (top) + product (center–bottom) ─────────────
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (screenSize.width * 0.055).clamp(30.0, 84.0),
            ),
            child: Column(
              children: [
                // Title occupies the red section
                SizedBox(
                  height: screenSize.height * redFraction,
                  child: Center(
                    child: _TodaysSpecialTitle(
                      screenWidth: screenSize.width,
                      fontScale: headingFontScale,
                      language: displayLanguage,
                    ),
                  ),
                ),

                // Product card occupies the yellow section
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      // ── Transitions — untouched ────────────────────────
                      duration: Duration(
                        milliseconds: (transitionSpeedSeconds * 1000).round(),
                      ),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        switch (transitionStyle.toLowerCase()) {
                          case 'slide':
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'zoom':
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.98, end: 1)
                                  .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'flip':
                            return RotationTransition(
                              turns: Tween<double>(begin: -0.01, end: 0)
                                  .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'fade':
                          default:
                            return FadeTransition(
                                opacity: animation, child: child);
                        }
                      },
                      // ──────────────────────────────────────────────────
                      child: RepaintBoundary(
                        key: productKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: pageItems
                              .map(
                                (item) => Expanded(
                                  child: _TodaysStarProduct(
                                    item: item,
                                    nameSize: nameSize,
                                    priceSize: priceSize,
                                    showPrice: showPrice,
                                    showProductImage: showProductImage,
                                    maxImageSize: min(
                                      screenSize.width * 0.46,
                                      screenSize.height * 0.44,
                                    ).clamp(220.0, 500.0),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom breathing room
                SizedBox(
                  height: (screenSize.height * 0.04).clamp(16.0, 40.0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Two-tone poster background: crimson red top → warm yellow bottom ──────────
class _PosterBackground extends StatelessWidget {
  const _PosterBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PosterBackgroundPainter(),
    );
  }
}

class _PosterBackgroundPainter extends CustomPainter {
  const _PosterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final isLandscape = size.width > size.height;

    // Landscape keeps the same bold diagonal; portrait uses a shallower,
    // slimmer band so it doesn't dominate the tall layout.
    final splitY = size.height * 0.46;
    final dy = isLandscape ? size.height * 0.06 : size.height * 0.028;
    final bandThickness = isLandscape ? 22.0 : 14.0;

    // ── Red top panel (fills full canvas first) ────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kPosterRedDark, _kPosterRed, _kPosterRedLight],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, splitY)),
    );

    // ── Yellow-orange bottom panel ─────────────────────────────────────────
    // Diagonal top edge matches the band geometry exactly — no seam.
    final yellowPath = Path()
      ..moveTo(0, splitY + dy)
      ..lineTo(size.width, splitY - dy)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      yellowPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_kPosterYellowLight, _kPosterYellow, _kPosterOrange],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
          Rect.fromLTWH(0, splitY, size.width, size.height - splitY),
        ),
    );

    // ── Diagonal divider band ──────────────────────────────────────────────
    final upperLeft = Offset(0, splitY + dy - bandThickness);
    final upperRight = Offset(size.width, splitY - dy - bandThickness);
    final lowerLeft = Offset(0, splitY + dy + bandThickness);
    final lowerRight = Offset(size.width, splitY - dy + bandThickness);

    final bandPath = Path()
      ..moveTo(upperLeft.dx, upperLeft.dy)
      ..lineTo(upperRight.dx, upperRight.dy)
      ..lineTo(lowerRight.dx, lowerRight.dy)
      ..lineTo(lowerLeft.dx, lowerLeft.dy)
      ..close();

    // Soft shadow beneath band
    canvas.drawPath(
      bandPath,
      Paint()
        ..color = Colors.black.withValues(alpha: isLandscape ? 0.18 : 0.12)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          isLandscape ? 10 : 6,
        ),
    );

    // White band fill
    canvas.drawPath(bandPath, Paint()..color = Colors.white);

    // Accent lines framing the band
    canvas.drawLine(
      lowerLeft,
      lowerRight,
      Paint()
        ..color = _kPosterYellow.withValues(alpha: 0.70)
        ..strokeWidth = isLandscape ? 3.0 : 2.0
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      upperLeft,
      upperRight,
      Paint()
        ..color = _kPosterRedLight.withValues(alpha: 0.60)
        ..strokeWidth = isLandscape ? 3.0 : 2.0
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Decorative garnish overlay ────────────────────────────────────────────────
// Replaces the food-icon garnishes with poster-accurate geometric decorations:
// white dot grids, hollow circle rings, triangle accents, wavy squiggles.
class _PosterGarnishLayer extends StatelessWidget {
  final Size screenSize;
  const _PosterGarnishLayer({required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final w = screenSize.width;
    final h = screenSize.height;

    return Stack(
      children: [
        // Top-left dot cluster
        Positioned(
          left: w * 0.03,
          top: h * 0.04,
          child: _DotGrid(
            columns: 4,
            rows: 4,
            spacing: (w * 0.016).clamp(8.0, 18.0),
            dotRadius: (w * 0.004).clamp(2.5, 5.0),
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),

        // Top-right dot cluster
        Positioned(
          right: w * 0.04,
          top: h * 0.03,
          child: _DotGrid(
            columns: 4,
            rows: 4,
            spacing: (w * 0.016).clamp(8.0, 18.0),
            dotRadius: (w * 0.004).clamp(2.5, 5.0),
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),

        // Red section — wavy squiggle left
        Positioned(
          left: w * 0.055,
          top: h * 0.22,
          child: _WavyLine(
            width: (w * 0.08).clamp(40.0, 90.0),
            amplitude: 6.0,
            color: Colors.white.withValues(alpha: 0.50),
            strokeWidth: 2.2,
          ),
        ),

        // Red section — wavy squiggle right
        Positioned(
          right: w * 0.055,
          top: h * 0.18,
          child: _WavyLine(
            width: (w * 0.08).clamp(40.0, 90.0),
            amplitude: 6.0,
            color: Colors.white.withValues(alpha: 0.50),
            strokeWidth: 2.2,
          ),
        ),

        // Red section — hollow ring top-right
        Positioned(
          right: w * 0.12,
          top: h * 0.06,
          child: _HollowCircle(
            diameter: (w * 0.045).clamp(22.0, 48.0),
            color: Colors.white.withValues(alpha: 0.38),
            strokeWidth: 2.0,
          ),
        ),

        // Red section — small hollow ring left
        Positioned(
          left: w * 0.14,
          top: h * 0.10,
          child: _HollowCircle(
            diameter: (w * 0.028).clamp(14.0, 30.0),
            color: Colors.white.withValues(alpha: 0.32),
            strokeWidth: 1.6,
          ),
        ),

        // Yellow section — triangle accent left
        Positioned(
          left: w * 0.06,
          top: h * 0.56,
          child: _TriangleAccent(
            size: (w * 0.030).clamp(16.0, 32.0),
            color: Colors.white.withValues(alpha: 0.60),
            filled: false,
          ),
        ),

        // Yellow section — triangle accent left (small offset)
        Positioned(
          left: w * 0.105,
          top: h * 0.59,
          child: _TriangleAccent(
            size: (w * 0.022).clamp(12.0, 24.0),
            color: Colors.white.withValues(alpha: 0.40),
            filled: false,
          ),
        ),

        // Yellow section — triangle accent right
        Positioned(
          right: w * 0.06,
          top: h * 0.54,
          child: _TriangleAccent(
            size: (w * 0.030).clamp(16.0, 32.0),
            color: Colors.white.withValues(alpha: 0.60),
            filled: false,
          ),
        ),

        // Yellow section — triangle accent right (small offset)
        Positioned(
          right: w * 0.105,
          top: h * 0.58,
          child: _TriangleAccent(
            size: (w * 0.022).clamp(12.0, 24.0),
            color: Colors.white.withValues(alpha: 0.40),
            filled: false,
          ),
        ),

        // Yellow section — bubble circles
        Positioned(
          left: w * 0.08,
          bottom: h * 0.18,
          child: _HollowCircle(
            diameter: (w * 0.038).clamp(18.0, 42.0),
            color: Colors.white.withValues(alpha: 0.35),
            strokeWidth: 1.8,
          ),
        ),
        Positioned(
          left: w * 0.14,
          bottom: h * 0.12,
          child: _HollowCircle(
            diameter: (w * 0.022).clamp(10.0, 24.0),
            color: Colors.white.withValues(alpha: 0.28),
            strokeWidth: 1.4,
          ),
        ),
        Positioned(
          right: w * 0.09,
          bottom: h * 0.16,
          child: _HollowCircle(
            diameter: (w * 0.034).clamp(16.0, 38.0),
            color: Colors.white.withValues(alpha: 0.35),
            strokeWidth: 1.8,
          ),
        ),

        // Yellow section — wavy squiggle bottom-left
        Positioned(
          left: w * 0.055,
          bottom: h * 0.07,
          child: _WavyLine(
            width: (w * 0.07).clamp(36.0, 80.0),
            amplitude: 5.0,
            color: Colors.white.withValues(alpha: 0.45),
            strokeWidth: 2.0,
          ),
        ),

        // Yellow section — wavy squiggle bottom-right
        Positioned(
          right: w * 0.055,
          bottom: h * 0.07,
          child: _WavyLine(
            width: (w * 0.07).clamp(36.0, 80.0),
            amplitude: 5.0,
            color: Colors.white.withValues(alpha: 0.45),
            strokeWidth: 2.0,
          ),
        ),
      ],
    );
  }
}

// ── Garnish primitive widgets ─────────────────────────────────────────────────

class _DotGrid extends StatelessWidget {
  final int columns;
  final int rows;
  final double spacing;
  final double dotRadius;
  final Color color;

  const _DotGrid({
    required this.columns,
    required this.rows,
    required this.spacing,
    required this.dotRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: columns * spacing,
      height: rows * spacing,
      child: CustomPaint(
        painter: _DotGridPainter(
          columns: columns,
          rows: rows,
          spacing: spacing,
          dotRadius: dotRadius,
          color: color,
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double spacing;
  final double dotRadius;
  final Color color;

  const _DotGridPainter({
    required this.columns,
    required this.rows,
    required this.spacing,
    required this.dotRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        canvas.drawCircle(
          Offset(c * spacing + spacing / 2, r * spacing + spacing / 2),
          dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HollowCircle extends StatelessWidget {
  final double diameter;
  final Color color;
  final double strokeWidth;

  const _HollowCircle({
    required this.diameter,
    required this.color,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _HollowCirclePainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _HollowCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _HollowCirclePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 2 - strokeWidth / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TriangleAccent extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;

  const _TriangleAccent({
    required this.size,
    required this.color,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TrianglePainter(color: color, filled: filled),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool filled;

  const _TrianglePainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavyLine extends StatelessWidget {
  final double width;
  final double amplitude;
  final Color color;
  final double strokeWidth;

  const _WavyLine({
    required this.width,
    required this.amplitude,
    required this.color,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: amplitude * 2 + strokeWidth,
      child: CustomPaint(
        painter: _WavyLinePainter(
          amplitude: amplitude,
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _WavyLinePainter extends CustomPainter {
  final double amplitude;
  final Color color;
  final double strokeWidth;

  const _WavyLinePainter({
    required this.amplitude,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2);
    final segW = size.width / 8;
    for (var i = 0; i < 8; i++) {
      final x = i * segW;
      path.quadraticBezierTo(
        x + segW / 2,
        i.isEven ? 0 : size.height,
        x + segW,
        size.height / 2,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Title widget — poster "Today SPECIAL MENU" style ─────────────────────────
// English: italic yellow "Today" above bold white "SPECIAL" / "MENU" stack.
// Malayalam: single large bold white line (unchanged layout).
// All font-scale and language logic is preserved.
class _TodaysSpecialTitle extends StatelessWidget {
  final double screenWidth;
  final double fontScale;
  final String language;

  const _TodaysSpecialTitle({
    required this.screenWidth,
    required this.fontScale,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (_isMalayalam(language)) {
      // Malayalam path — unchanged from original
      final fontSize = ((screenWidth * 0.076) * fontScale).clamp(48.0, 124.0);
      return SizedBox(
        width: double.infinity,
        child: Text(
          _localizedTodaysStar(language),
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansMalayalam(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: const [
              Shadow(
                color: Color(0xCC000000),
                offset: Offset(0, 10),
                blurRadius: 22,
              ),
            ],
          ),
        ),
      );
    }

    // English poster layout
    final todaySize = ((screenWidth * 0.054) * fontScale).clamp(38.0, 92.0);
    final specialSize = ((screenWidth * 0.100) * fontScale).clamp(72.0, 172.0);
    final menuSize = ((screenWidth * 0.072) * fontScale).clamp(52.0, 124.0);

    const textShadow = [
      Shadow(
        color: Color(0x88000000),
        offset: Offset(0, 6),
        blurRadius: 14,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Today" — italic yellow script-weight
        Text(
          "Today's",
          textAlign: TextAlign.center,
          style: GoogleFonts.dancingScript(
            fontSize: todaySize,
            color: _kPosterYellowLight,
            fontWeight: FontWeight.w700,
            height: 1.0,
            shadows: textShadow,
          ),
        ),

        // "SPECIAL" — heavy white condensed
        Text(
          'SPECIAL',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: specialSize,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 0.92,
            letterSpacing: -1.0,
            shadows: textShadow,
          ),
        ),

        // "MENU" — heavy white, slightly smaller
        Text(
          'ITEM',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: menuSize,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 0.96,
            letterSpacing: 2.0,
            shadows: textShadow,
          ),
        ),
      ],
    );
  }
}

// ── Product card — circular image + name + price pill ────────────────────────
// Signature element: food image lifted in a white-bordered circle that straddles
// the torn divider, visually anchoring the two colour zones together.
// All showPrice / showProductImage / availability / font-scale flags preserved.
class _TodaysStarProduct extends StatelessWidget {
  final MenuItem item;
  final double nameSize;
  final double priceSize;
  final bool showPrice;
  final bool showProductImage;
  final double maxImageSize;

  const _TodaysStarProduct({
    required this.item,
    required this.nameSize,
    required this.priceSize,
    required this.showPrice,
    required this.showProductImage,
    required this.maxImageSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = min(
          maxImageSize,
          min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.68),
        );

        final product = FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular food image with white ring border
                if (showProductImage) ...[
                  _PosterProductImage(item: item, size: imageSize),
                  SizedBox(height: imageSize * 0.04),
                ],

                // Item name — bold white
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: nameSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 0.98,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Price pill — white rounded badge with red text
                if (showPrice) ...[
                  const SizedBox(height: 14),
                  _TodaysStarPriceChip(item: item, fontSize: priceSize),
                ],
              ],
            ),
          ),
        );

        // Availability dimming — unchanged
        return _UnavailableTreatment(
          enabled: !item.isAvailable,
          child: product,
        );
      },
    );
  }
}

// ── Circular product image with white border ring ─────────────────────────────
class _PosterProductImage extends StatelessWidget {
  final MenuItem item;
  final double size;

  const _PosterProductImage({required this.item, required this.size});

  @override
  Widget build(BuildContext context) {
    final borderWidth = (size * 0.038).clamp(4.0, 12.0);
    final outerRingWidth = (size * 0.018).clamp(2.0, 6.0);
    final innerSize = size - outerRingWidth * 2 - 4;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative ring (thin, semi-transparent white)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: outerRingWidth,
              ),
            ),
          ),

          // Shadow behind the image circle
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: _kPosterYellow.withValues(alpha: 0.22),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ],
            ),
          ),

          // White border ring — purely decorative, sits behind the clipped image
          Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),

          // Image clipped to a true circle via ClipOval, inset by borderWidth
          ClipOval(
            child: SizedBox(
              width: innerSize - borderWidth * 2,
              height: innerSize - borderWidth * 2,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 120),
                      fadeOutDuration: Duration.zero,
                      placeholder: (_, __) => const _StarPlaceholder(),
                      errorWidget: (_, __, ___) => const _StarPlaceholder(),
                    )
                  : const _StarPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Price chip — white pill badge ─────────────────────────────────────────────
class _TodaysStarPriceChip extends StatelessWidget {
  final MenuItem item;
  final double fontSize;

  const _TodaysStarPriceChip({required this.item, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final text = item.priceVariants.isNotEmpty
        ? item.priceVariants
            .map((v) => '${v.label}  Rs. ${v.price.toStringAsFixed(0)}')
            .join('   ')
        : 'Rs. ${item.price.toStringAsFixed(0)}';

    final effectiveFontSize =
        item.priceVariants.isNotEmpty ? fontSize * 0.72 : fontSize;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (fontSize * 0.72).clamp(14.0, 36.0),
        vertical: (fontSize * 0.22).clamp(6.0, 14.0),
      ),
      decoration: BoxDecoration(
        color: _kPosterRed,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: effectiveFontSize,
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
          height: 1.1,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Placeholder for missing/loading images ────────────────────────────────────
class _StarPlaceholder extends StatelessWidget {
  const _StarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF0EAD8),
      child: Center(
        child: Text(
          'SPECIAL',
          style: TextStyle(
            color: _kPosterRed,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ── Availability treatment — unchanged from original ──────────────────────────
class _UnavailableTreatment extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const _UnavailableTreatment({
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Opacity(
      opacity: 0.46,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All widgets below this line are UNCHANGED from the original file.
// ─────────────────────────────────────────────────────────────────────────────
