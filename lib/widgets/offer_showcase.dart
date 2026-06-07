import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_environment.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class _PremiumTokens {
  static const Color bgDeep = Color(0xFF0D0A08);
  static const Color bgMid = Color(0xFF1A1410);
  static const Color goldPrimary = Color(0xFFD4A855);
  static const Color goldLight = Color(0xFFF0C878);
  static const Color goldDim = Color(0xFF8C6E35);
  static const Color textMuted = Color(0xFFB0A898);
}

class OfferShowcase extends StatelessWidget {
  final List<MenuItem> offers;
  final int pageIndex;
  final TvMenuThemeData theme;
  final Size screenSize;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final String displayLanguage;
  final String? businessName;
  final String? businessLogoUrl;

  const OfferShowcase({
    super.key,
    required this.offers,
    required this.pageIndex,
    required this.theme,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.displayLanguage,
    this.businessName,
    this.businessLogoUrl,
  });

  static int offersPerPageFor(Size size) => 1;

  static int pageCountFor(List<MenuItem> offers, Size size) {
    if (offers.isEmpty) return 0;
    return _buildOfferPages(offers).length;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildOfferPages(offers);
    if (pages.isEmpty) return const SizedBox.shrink();

    final safePage = pageIndex % pages.length;
    final page = pages[safePage];

    return AnimatedSwitcher(
      duration: Duration(milliseconds: (transitionSpeedSeconds * 1000).round()),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        switch (transitionStyle.toLowerCase()) {
          case 'slide':
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case 'zoom':
            return ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case 'flip':
            return RotationTransition(
              turns: Tween<double>(begin: -0.01, end: 0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case 'fade':
          default:
            return FadeTransition(opacity: animation, child: child);
        }
      },
      child: _OfferFeature(
        key: ValueKey(
            'offer-$safePage-${page.offer.id}-${page.item?.id ?? 'all'}'),
        offer: page.offer,
        freeItem: page.item,
        theme: theme,
        screenSize: screenSize,
        headingFontScale: headingFontScale,
        nameFontScale: nameFontScale,
        priceFontScale: priceFontScale,
        showPrice: showPrice,
        showProductImage: showProductImage,
        displayLanguage: displayLanguage,
        businessLogoUrl: businessLogoUrl,
      ),
    );
  }
}

class _OfferPage {
  final MenuItem offer;
  final ComboOfferItem? item;

  const _OfferPage({
    required this.offer,
    this.item,
  });
}

List<_OfferPage> _buildOfferPages(List<MenuItem> offers) {
  final pages = <_OfferPage>[];
  for (final offer in offers) {
    if (offer.offerType == 'free' && offer.comboItems.isNotEmpty) {
      pages.addAll(
        offer.comboItems.map(
          (item) => _OfferPage(
            offer: offer,
            item: item,
          ),
        ),
      );
      continue;
    }
    pages.add(_OfferPage(offer: offer));
  }
  return pages;
}

class _OfferFeature extends StatelessWidget {
  final MenuItem offer;
  final ComboOfferItem? freeItem;
  final TvMenuThemeData theme;
  final Size screenSize;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final String displayLanguage;
  final String? businessLogoUrl;

  const _OfferFeature({
    super.key,
    required this.offer,
    required this.freeItem,
    required this.theme,
    required this.screenSize,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.displayLanguage,
    required this.businessLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (offer.offerType == 'free') {
      return _FreeOfferPoster(
        offer: offer,
        item: freeItem,
        screenSize: screenSize,
        showProductImage: showProductImage,
        headingFontScale: headingFontScale,
        nameFontScale: nameFontScale,
        priceFontScale: priceFontScale,
        displayLanguage: displayLanguage,
        businessLogoUrl: businessLogoUrl,
      );
    }

    return _PremiumDiscountOffer(
      offer: offer,
      theme: theme,
      screenSize: screenSize,
      headingFontScale: headingFontScale,
      nameFontScale: nameFontScale,
      priceFontScale: priceFontScale,
      showPrice: showPrice,
      showProductImage: showProductImage,
      displayLanguage: displayLanguage,
      businessLogoUrl: businessLogoUrl,
    );
  }
}

class _PremiumDiscountOffer extends StatelessWidget {
  final MenuItem offer;
  final TvMenuThemeData theme;
  final Size screenSize;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final String displayLanguage;
  final String? businessLogoUrl;

  const _PremiumDiscountOffer({
    required this.offer,
    required this.theme,
    required this.screenSize,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.displayLanguage,
    required this.businessLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = (screenSize.width * 0.056).clamp(48.0, 88.0);
    final sideInset = (screenSize.width * 0.055).clamp(28.0, 72.0);
    final topInset = (screenSize.height * 0.032).clamp(18.0, 40.0);
    final bottomInset = (screenSize.height * 0.036).clamp(20.0, 44.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _PremiumBackground()),
        Positioned(
          top: topInset,
          right: sideInset,
          child: _PremiumBusinessLogo(
            logoUrl: businessLogoUrl,
            size: logoSize,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                sideInset, topInset, sideInset, bottomInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _PremiumLayout(
                  constraints: constraints,
                  offer: offer,
                  screenSize: screenSize,
                  headingFontScale: headingFontScale,
                  nameFontScale: nameFontScale,
                  priceFontScale: priceFontScale,
                  showPrice: showPrice,
                  showProductImage: showProductImage,
                  displayLanguage: displayLanguage,
                  theme: theme,
                );
              },
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _PremiumOverlayPainter()),
          ),
        ),
      ],
    );
  }
}

class _PremiumLayout extends StatelessWidget {
  final BoxConstraints constraints;
  final MenuItem offer;
  final Size screenSize;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final String displayLanguage;
  final TvMenuThemeData theme;

  const _PremiumLayout({
    required this.constraints,
    required this.offer,
    required this.screenSize,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.displayLanguage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cw = constraints.maxWidth;
    final ch = constraints.maxHeight;
    final isCompact = ch < 620;
    final isPortraitPoster = ch > cw * 1.18;

    final eyebrowSize = ((cw * 0.022) * headingFontScale).clamp(11.0, 20.0);
    final titleSize =
        ((cw * 0.082) * nameFontScale).clamp(32.0, isCompact ? 70.0 : 112.0);
    final taglineSize = isPortraitPoster
        ? ((cw * 0.052) * headingFontScale).clamp(30.0, 66.0)
        : ((cw * 0.034) * headingFontScale)
            .clamp(16.0, isCompact ? 32.0 : 50.0);
    final footerSize =
        ((cw * 0.018) * headingFontScale).clamp(11.0, isCompact ? 20.0 : 28.0);

    final footerGap = (ch * 0.010).clamp(4.0, 14.0);

    const eyebrowTop = 0.0;
    final eyebrowH = eyebrowSize * 2.2;
    final dividerTop = eyebrowTop + eyebrowH + (isCompact ? 4.0 : 8.0);
    const dividerH = 1.0;
    final titleTop = dividerTop + dividerH + (isCompact ? 8.0 : 14.0);
    final titleH = titleSize * 1.06;
    final defaultTagTop = titleTop + titleH + (isCompact ? 6.0 : 12.0);
    final tagTop =
        isPortraitPoster ? max(defaultTagTop, ch * 0.245) : defaultTagTop;
    final tagH = taglineSize * 1.12;
    final listTop = tagTop + tagH + (isCompact ? 12.0 : 24.0);
    final footerH = footerSize * 1.2;
    final listBottom = footerH + footerGap;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: eyebrowTop,
          left: 0,
          right: 0,
          height: eyebrowH,
          child: _EyebrowLabel(
            fontSize: eyebrowSize,
            language: displayLanguage,
          ),
        ),
        Positioned(
          top: dividerTop,
          left: cw * 0.14,
          right: cw * 0.14,
          height: dividerH,
          child: CustomPaint(painter: _GoldDividerPainter()),
        ),
        Positioned(
          top: titleTop,
          left: cw * 0.06,
          right: cw * 0.06,
          height: titleH,
          child: _GoldTitleText(text: offer.name, fontSize: titleSize),
        ),
        Positioned(
          top: tagTop,
          left: 0,
          right: 0,
          height: tagH,
          child: _TaglineText(fontSize: taglineSize, language: displayLanguage),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: listTop,
          bottom: listBottom,
          child: _DiscountOfferProductGrid(
            offer: offer,
            maxWidth: cw * 0.92,
            showProductImage: showProductImage,
            showPrice: showPrice,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: footerH,
          child: _FooterTagline(
            fontSize: footerSize,
            language: displayLanguage,
          ),
        ),
      ],
    );
  }
}

class _FreeOfferPoster extends StatelessWidget {
  final MenuItem offer;
  final ComboOfferItem? item;
  final Size screenSize;
  final bool showProductImage;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final String displayLanguage;
  final String? businessLogoUrl;

  const _FreeOfferPoster({
    required this.offer,
    required this.item,
    required this.screenSize,
    required this.showProductImage,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.displayLanguage,
    required this.businessLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final width = screenSize.width;
    final height = screenSize.height;
    final posterItem =
        item ?? (offer.comboItems.isNotEmpty ? offer.comboItems.first : null);
    final buyQty = posterItem?.buyQuantity ?? posterItem?.quantity ?? 1;
    final freeQty = posterItem?.freeQuantity ?? 1;
    final offerDetail = posterItem == null
        ? _isMalayalam(displayLanguage)
            ? '$buyQty വാങ്ങൂ, $freeQty സൗജന്യം'
            : 'Buy $buyQty, get $freeQty free'
        : _freeOfferPosterDetail(
            displayLanguage,
            posterItem,
            buyQty,
            freeQty,
          );
    final sideInset = (width * 0.055).clamp(28.0, 78.0);
    final topInset = (height * 0.034).clamp(20.0, 44.0);
    final logoSize = (width * 0.052).clamp(48.0, 84.0);
    final isWidePoster = width / height > 1.35;
    final titleSize = ((width * 0.058) * nameFontScale)
        .clamp(34.0, isWidePoster ? 86.0 : 72.0);
    final detailSize = ((width * 0.022) * headingFontScale)
        .clamp(18.0, isWidePoster ? 34.0 : 30.0);
    final offerWordSize = ((width * 0.078) * priceFontScale)
        .clamp(62.0, isWidePoster ? 126.0 : 112.0);
    final numberSize = ((width * 0.145) * priceFontScale)
        .clamp(116.0, isWidePoster ? 236.0 : 210.0);
    final productSize =
        (isWidePoster ? height * 0.42 : width * 0.44).clamp(170.0, 420.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _PremiumBackground()),
        Positioned(
          top: topInset,
          right: sideInset,
          child: _PremiumBusinessLogo(
            logoUrl: businessLogoUrl,
            size: logoSize,
          ),
        ),
        SafeArea(
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(sideInset, topInset, sideInset, topInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cw = constraints.maxWidth;
                final ch = constraints.maxHeight;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: logoSize + 18,
                      child: _EyebrowLabel(
                        fontSize:
                            ((cw * 0.022) * headingFontScale).clamp(12.0, 22.0),
                        language: displayLanguage,
                      ),
                    ),
                    Positioned(
                      top: ch * 0.11,
                      left: 0,
                      right: 0,
                      child: _GoldTitleText(
                        text: offer.name,
                        fontSize: titleSize,
                      ),
                    ),
                    if (isWidePoster) ...[
                      Positioned(
                        top: ch * 0.34,
                        left: 0,
                        width: productSize,
                        height: productSize,
                        child: _PosterFoodImage(
                          item: posterItem,
                          showProductImage: showProductImage,
                          preferFreeProduct: false,
                        ),
                      ),
                      Positioned(
                        top: ch * 0.34,
                        right: 0,
                        width: productSize,
                        height: productSize,
                        child: _PosterFoodImage(
                          item: posterItem,
                          showProductImage: showProductImage,
                          preferFreeProduct: true,
                        ),
                      ),
                    ] else ...[
                      Positioned(
                        top: ch * 0.15,
                        left: (cw - productSize) / 2,
                        width: productSize,
                        height: productSize,
                        child: _PosterFoodImage(
                          item: posterItem,
                          showProductImage: showProductImage,
                          preferFreeProduct: false,
                        ),
                      ),
                      Positioned(
                        bottom: ch * 0.02,
                        left: (cw - productSize) / 2,
                        width: productSize,
                        height: productSize,
                        child: _PosterFoodImage(
                          item: posterItem,
                          showProductImage: showProductImage,
                          preferFreeProduct: true,
                        ),
                      ),
                    ],
                    Positioned(
                      top: isWidePoster ? ch * 0.38 : ch * 0.47,
                      left: isWidePoster ? cw * 0.28 : cw * 0.06,
                      right: isWidePoster ? cw * 0.28 : cw * 0.06,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _BuyGetHeadline(
                            buyQty: buyQty,
                            freeQty: freeQty,
                            language: displayLanguage,
                            offerWordSize: offerWordSize,
                            numberSize: numberSize,
                          ),
                          SizedBox(height: (ch * 0.018).clamp(8.0, 18.0)),
                          _BuyGetDetailText(
                            detail: offerDetail,
                            fontSize: detailSize,
                            splitLines: isWidePoster,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _PremiumOverlayPainter()),
          ),
        ),
      ],
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.22),
          radius: 1.22,
          colors: [
            Color(0xFF302018),
            _PremiumTokens.bgMid,
            _PremiumTokens.bgDeep,
          ],
          stops: [0.0, 0.46, 1.0],
        ),
      ),
      child: CustomPaint(painter: _PremiumBackgroundPainter()),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  const _PremiumBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.48);
    final gold = Paint()
      ..color = _PremiumTokens.goldPrimary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var i = 0; i < 8; i++) {
      canvas.drawCircle(center, size.shortestSide * (0.12 + i * 0.07), gold);
    }

    final linePaint = Paint()
      ..color = _PremiumTokens.goldPrimary.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 42) {
      canvas.drawLine(
          Offset(x, 0), Offset(x + size.height, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumOverlayPainter extends CustomPainter {
  const _PremiumOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.92,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.34),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final corner = Paint()
      ..color = _PremiumTokens.goldPrimary.withValues(alpha: 0.42)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const length = 58.0;
    const inset = 18.0;
    canvas
      ..drawLine(const Offset(inset, inset),
          const Offset(inset + length, inset), corner)
      ..drawLine(const Offset(inset, inset),
          const Offset(inset, inset + length), corner)
      ..drawLine(Offset(size.width - inset, inset),
          Offset(size.width - inset - length, inset), corner)
      ..drawLine(Offset(size.width - inset, inset),
          Offset(size.width - inset, inset + length), corner)
      ..drawLine(Offset(inset, size.height - inset),
          Offset(inset + length, size.height - inset), corner)
      ..drawLine(Offset(inset, size.height - inset),
          Offset(inset, size.height - inset - length), corner)
      ..drawLine(Offset(size.width - inset, size.height - inset),
          Offset(size.width - inset - length, size.height - inset), corner)
      ..drawLine(Offset(size.width - inset, size.height - inset),
          Offset(size.width - inset, size.height - inset - length), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumBusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _PremiumBusinessLogo({
    required this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _absoluteImageUrl(logoUrl);
    if (imageUrl == null) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _PremiumTokens.goldPrimary, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _PremiumTokens.goldPrimary.withValues(alpha: 0.22),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  final double fontSize;
  final String language;

  const _EyebrowLabel({required this.fontSize, required this.language});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TinyDiamond(size: fontSize * 0.55),
        SizedBox(width: fontSize * 0.55),
        Text(
          _comboLocalized(language, 'eyebrow'),
          style: GoogleFonts.cormorantGaramond(
            color: _PremiumTokens.goldPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: fontSize * 0.30,
            height: 1,
          ),
        ),
        SizedBox(width: fontSize * 0.55),
        _TinyDiamond(size: fontSize * 0.55),
      ],
    );
  }
}

class _TinyDiamond extends StatelessWidget {
  final double size;

  const _TinyDiamond({required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: _PremiumTokens.goldPrimary, width: 1.0),
          ),
        ),
      ),
    );
  }
}

class _GoldDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          _PremiumTokens.goldPrimary.withValues(alpha: 0.0),
          _PremiumTokens.goldPrimary.withValues(alpha: 0.65),
          _PremiumTokens.goldPrimary,
          _PremiumTokens.goldPrimary.withValues(alpha: 0.65),
          _PremiumTokens.goldPrimary.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoldTitleText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _GoldTitleText({
    required this.text,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 980,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              text.toUpperCase(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cormorantGaramond(
                color: Colors.black.withValues(alpha: 0.60),
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 0.88,
                letterSpacing: fontSize * 0.025,
              ),
            ),
            Transform.translate(
              offset: Offset(-fontSize * 0.025, -fontSize * 0.032),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5D98A),
                    Color(0xFFD4A855),
                    Color(0xFFB8882E),
                    Color(0xFFD4A855),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ).createShader(bounds),
                child: Text(
                  text.toUpperCase(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 0.88,
                    letterSpacing: fontSize * 0.025,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaglineText extends StatelessWidget {
  final double fontSize;
  final String language;

  const _TaglineText({required this.fontSize, required this.language});

  @override
  Widget build(BuildContext context) {
    return Text(
      _comboLocalized(language, 'todaysBestDeal'),
      textAlign: TextAlign.center,
      style: GoogleFonts.playfairDisplay(
        color: _PremiumTokens.textMuted,
        fontSize: fontSize,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: 0.5,
        shadows: const [
          Shadow(
            color: Color(0x66000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}

class _PremiumHeroDish extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showProductImage;

  const _PremiumHeroDish({
    required this.imageUrl,
    required this.size,
    required this.showProductImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Positioned(
          //   bottom: size * 0.05,
          //   child: Container(
          //     width: size * 0.62,
          //     height: size * 0.12,
          //     decoration: BoxDecoration(
          //       color: Colors.transparent,
          //       borderRadius: BorderRadius.circular(size),
          //       boxShadow: [
          //         BoxShadow(
          //           color: _PremiumTokens.goldPrimary.withValues(alpha: 0.20),
          //           blurRadius: 38,
          //           spreadRadius: 10,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Positioned(
            top: size * 0.04,
            child: CustomPaint(
              size: Size(size * 0.86, size * 0.86),
              painter: _RingOrnamentPainter(),
            ),
          ),
          Positioned(
            top: size * 0.04,
            left: size * 0.04,
            right: size * 0.04,
            bottom: size * 0.04,
            child: !showProductImage || imageUrl == null
                ? const _PremiumImageFallback(label: 'COMBO')
                : ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const _PremiumImageFallback(label: 'COMBO'),
                      errorWidget: (_, __, ___) =>
                          const _PremiumImageFallback(label: 'COMBO'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RingOrnamentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.49;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    paint.color = _PremiumTokens.goldPrimary.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, paint);
    paint.color = _PremiumTokens.goldPrimary.withValues(alpha: 0.10);
    paint.strokeWidth = 0.6;
    canvas.drawCircle(center, radius * 0.84, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiscountOfferProductGrid extends StatelessWidget {
  final MenuItem offer;
  final double maxWidth;
  final bool showProductImage;
  final bool showPrice;

  const _DiscountOfferProductGrid({
    required this.offer,
    required this.maxWidth,
    required this.showProductImage,
    required this.showPrice,
  });

  @override
  Widget build(BuildContext context) {
    final items = offer.comboItems;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = (constraints.maxWidth * 0.025).clamp(14.0, 28.0);
            final tileWidth = constraints.maxWidth;
            final tileHeight =
                (constraints.maxWidth * 0.20).clamp(170.0, 320.0);
            final offerItems = items.isEmpty ? <ComboOfferItem>[] : items;

            return SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.isEmpty
                    ? [
                        _DiscountOfferSingleTile(
                          offer: offer,
                          width: tileWidth,
                          height: tileHeight,
                          showProductImage: showProductImage,
                          showPrice: showPrice,
                        ),
                      ]
                    : [
                        for (var i = 0; i < offerItems.length; i++) ...[
                          _DiscountOfferItemTile(
                            item: offerItems[i],
                            width: tileWidth,
                            height: tileHeight,
                            imageOnLeft: i.isEven,
                            showProductImage: showProductImage,
                            showPrice: showPrice,
                          ),
                          if (i != offerItems.length - 1) SizedBox(height: gap),
                        ],
                      ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscountOfferItemTile extends StatelessWidget {
  final ComboOfferItem item;
  final double width;
  final double height;
  final bool imageOnLeft;
  final bool showProductImage;
  final bool showPrice;

  const _DiscountOfferItemTile({
    required this.item,
    required this.width,
    required this.height,
    required this.imageOnLeft,
    required this.showProductImage,
    required this.showPrice,
  });

  @override
  Widget build(BuildContext context) {
    return _DiscountOfferTileShell(
      width: width,
      height: height,
      name: item.product.name,
      imageUrl: _absoluteImageUrl(item.product.imageUrl),
      mainPrice: _comboItemOriginalUnitPrice(item),
      offerPrice: _comboItemUnitPrice(item),
      imageOnLeft: imageOnLeft,
      showProductImage: showProductImage,
      showPrice: showPrice,
    );
  }
}

class _DiscountOfferSingleTile extends StatelessWidget {
  final MenuItem offer;
  final double width;
  final double height;
  final bool showProductImage;
  final bool showPrice;

  const _DiscountOfferSingleTile({
    required this.offer,
    required this.width,
    required this.height,
    required this.showProductImage,
    required this.showPrice,
  });

  @override
  Widget build(BuildContext context) {
    return _DiscountOfferTileShell(
      width: width,
      height: height,
      name: offer.name,
      imageUrl: _absoluteImageUrl(offer.imageUrl),
      mainPrice: offer.originalPrice ?? offer.price,
      offerPrice: offer.price,
      imageOnLeft: true,
      showProductImage: showProductImage,
      showPrice: showPrice,
    );
  }
}

class _DiscountOfferTileShell extends StatelessWidget {
  final double width;
  final double height;
  final String name;
  final String? imageUrl;
  final double mainPrice;
  final double offerPrice;
  final bool imageOnLeft;
  final bool showProductImage;
  final bool showPrice;

  const _DiscountOfferTileShell({
    required this.width,
    required this.height,
    required this.name,
    required this.imageUrl,
    required this.mainPrice,
    required this.offerPrice,
    required this.imageOnLeft,
    required this.showProductImage,
    required this.showPrice,
  });

  @override
  Widget build(BuildContext context) {
    final canShowImage = showProductImage && imageUrl != null;
    final imageSide = canShowImage ? min(height * 0.84, width * 0.26) : 0.0;
    final nameSize = (width * 0.045).clamp(28.0, 58.0);
    final mainPriceSize = (width * 0.024).clamp(18.0, 34.0);
    final offerPriceSize = (width * 0.038).clamp(28.0, 52.0);
    final imageGap = (width * 0.035).clamp(22.0, 44.0);
    final imageBlock = canShowImage
        ? SizedBox(
            width: imageSide,
            height: imageSide,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          )
        : const SizedBox.shrink();
    final textBlock = Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            imageOnLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            name.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: imageOnLeft ? TextAlign.left : TextAlign.right,
            style: GoogleFonts.cormorantGaramond(
              color: _PremiumTokens.goldLight,
              fontSize: nameSize,
              fontWeight: FontWeight.w800,
              height: 0.95,
              letterSpacing: 0,
            ),
          ),
          if (showPrice) ...[
            SizedBox(height: (width * 0.010).clamp(8.0, 16.0)),
            Text(
              'Rs ${mainPrice.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white54,
                decoration: TextDecoration.lineThrough,
                decorationColor: Colors.white54,
                fontSize: mainPriceSize,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: (width * 0.004).clamp(3.0, 8.0)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  imageOnLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: Text(
                'Rs ${offerPrice.toStringAsFixed(0)}',
                maxLines: 1,
                style: GoogleFonts.bebasNeue(
                  color: _PremiumTokens.goldLight,
                  fontSize: offerPriceSize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: (width * 0.014).clamp(12.0, 26.0),
          vertical: (width * 0.010).clamp(8.0, 18.0),
        ),
        child: Row(
          children: imageOnLeft
              ? [
                  if (canShowImage) imageBlock,
                  if (canShowImage) SizedBox(width: imageGap),
                  textBlock,
                ]
              : [
                  textBlock,
                  if (canShowImage) SizedBox(width: imageGap),
                  if (canShowImage) imageBlock,
                ],
        ),
      ),
    );
  }
}

class _FooterTagline extends StatelessWidget {
  final double fontSize;
  final String language;

  const _FooterTagline({required this.fontSize, required this.language});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF8C6E35), Color(0xFFD4A855), Color(0xFF8C6E35)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(bounds),
      child: Text(
        _comboLocalized(language, 'serveGreatness'),
        textAlign: TextAlign.center,
        style: GoogleFonts.cormorantGaramond(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: fontSize * 0.20,
          height: 1,
        ),
      ),
    );
  }
}

class _PremiumImageFallback extends StatelessWidget {
  final String label;

  const _PremiumImageFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _PremiumTokens.bgMid,
        border: Border.all(
          color: _PremiumTokens.goldDim.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.cormorantGaramond(
            color: _PremiumTokens.goldDim.withValues(alpha: 0.70),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _BuyGetHeadline extends StatelessWidget {
  final int buyQty;
  final int freeQty;
  final String language;
  final double offerWordSize;
  final double numberSize;

  const _BuyGetHeadline({
    required this.buyQty,
    required this.freeQty,
    required this.language,
    required this.offerWordSize,
    required this.numberSize,
  });

  @override
  Widget build(BuildContext context) {
    final isMalayalam = _isMalayalam(language);
    final textStyle = isMalayalam
        ? GoogleFonts.notoSansMalayalam(
            color: _PremiumTokens.goldLight,
            fontWeight: FontWeight.w900,
            height: 0.9,
            shadows: const [
              Shadow(
                color: Color(0xFF260B0B),
                offset: Offset(4, 5),
                blurRadius: 0,
              ),
            ],
          )
        : GoogleFonts.bebasNeue(
            color: _PremiumTokens.goldLight,
            fontWeight: FontWeight.w900,
            height: 0.82,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0xFF260B0B),
                offset: Offset(4, 5),
                blurRadius: 0,
              ),
            ],
          );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isMalayalam ? 'വാങ്ങൂ $buyQty' : 'BUY $buyQty',
                style: textStyle.copyWith(fontSize: offerWordSize),
              ),
              Text(
                isMalayalam ? 'നേടൂ' : 'GET',
                style: textStyle.copyWith(fontSize: offerWordSize * 0.92),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Text(
            '$freeQty',
            style: textStyle.copyWith(fontSize: numberSize),
          ),
        ],
      ),
    );
  }
}

class _BuyGetDetailText extends StatelessWidget {
  final String detail;
  final double fontSize;
  final bool splitLines;

  const _BuyGetDetailText({
    required this.detail,
    required this.fontSize,
    required this.splitLines,
  });

  @override
  Widget build(BuildContext context) {
    final lines = detail
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final style = GoogleFonts.nunito(
      color: _PremiumTokens.goldLight,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1.05,
    );

    if (splitLines && lines.length >= 2) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              lines.first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              lines.skip(1).join(' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: style,
            ),
          ),
        ],
      );
    }

    return Text(
      detail,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

class _PosterFoodImage extends StatelessWidget {
  final ComboOfferItem? item;
  final bool showProductImage;
  final bool preferFreeProduct;

  const _PosterFoodImage({
    required this.item,
    required this.showProductImage,
    required this.preferFreeProduct,
  });

  @override
  Widget build(BuildContext context) {
    final product = preferFreeProduct
        ? item?.freeProduct ?? item?.product
        : item?.product ?? item?.freeProduct;
    final imageUrl = _absoluteImageUrl(product?.imageUrl);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: _PremiumHeroDish(
            imageUrl: imageUrl,
            size: size,
            showProductImage: showProductImage,
          ),
        );
      },
    );
  }
}

String _freeProductLabel(ComboOfferItem item) {
  final name = item.freeProduct?.name ?? 'free';
  final variant = item.freeVariantLabel?.trim();
  if (variant == null || variant.isEmpty) return name;
  return '$name $variant';
}

String _productLabel(ComboOfferItem item) {
  final variant = item.variantLabel?.trim();
  if (variant == null || variant.isEmpty) return item.product.name;
  return '${item.product.name} $variant';
}

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _comboLocalized(String language, String key) {
  if (_isMalayalam(language)) {
    return switch (key) {
      'eyebrow' => 'കോംബോ സ്പെഷ്യൽ',
      'todaysBestDeal' => 'ഇന്നത്തെ ബെസ്റ്റ് ഡീൽ',
      'serveGreatness' => 'രുചിയുടെ സന്തോഷം',
      _ => key,
    };
  }
  return switch (key) {
    'eyebrow' => 'COMBO SPECIAL',
    'todaysBestDeal' => "Today's Best Deal",
    'serveGreatness' => 'WE SERVE YOU GREATNESS',
    _ => key,
  };
}

String _freeOfferPosterDetail(
  String language,
  ComboOfferItem item,
  int buyQty,
  int freeQty,
) {
  if (_isMalayalam(language)) {
    return '$buyQty ${_productLabel(item)} വാങ്ങൂ\n$freeQty ${_freeProductLabel(item)} സൗജന്യം';
  }
  return 'Buy $buyQty ${_productLabel(item)}\nGet $freeQty ${_freeProductLabel(item)} free';
}

double _comboItemUnitPrice(ComboOfferItem item) {
  if (item.discountPrice != null && item.discountPrice! > 0) {
    return item.discountPrice!;
  }
  return _comboItemOriginalUnitPrice(item);
}

double _comboItemOriginalUnitPrice(ComboOfferItem item) {
  if (item.variantPrice != null && item.variantPrice! > 0) {
    return item.variantPrice!;
  }
  final selectedLabel = item.variantLabel?.trim().toLowerCase();
  if (selectedLabel != null && selectedLabel.isNotEmpty) {
    for (final variant in item.product.priceVariants) {
      if (variant.label.trim().toLowerCase() == selectedLabel) {
        return variant.price;
      }
    }
  }
  if (item.product.price > 0) return item.product.price;
  if (item.product.priceVariants.isNotEmpty) {
    final fullVariant = item.product.priceVariants
        .where((variant) => variant.label.trim().toLowerCase() == 'full')
        .cast<PriceVariant?>()
        .firstWhere((_) => true, orElse: () => null);
    if (fullVariant != null) return fullVariant.price;
    return item.product.priceVariants.last.price;
  }
  return item.product.price;
}

String? _absoluteImageUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http')) return value;
  final path = value.startsWith('/') ? value.substring(1) : value;
  return '${AppEnvironment.contentBaseUrl}/$path';
}
