import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_environment.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// DESIGN TOKENS
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumTokens {
  // Core palette â€” deep charcoal base with ember gold accents
  static const Color bgDeep = Color(0xFF0D0A08);
  static const Color bgMid = Color(0xFF1A1410);
  static const Color bgSurface = Color(0xFF241E18);
  static const Color bgGlass = Color(0x22FFFFFF);
  static const Color goldPrimary = Color(0xFFD4A855);
  static const Color goldLight = Color(0xFFF0C878);
  static const Color goldDim = Color(0xFF8C6E35);
  static const Color textMuted = Color(0xFFB0A898);
  static const Color priceText = Color(0xFF0D0A08);
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PUBLIC ENTRY WIDGET  (API identical to original ComboOfferShowcase)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ComboOfferShowcase extends StatelessWidget {
  final List<MenuItem> combos;
  final int pageIndex;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final Size screenSize;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final bool showComboItemQuantity;
  final String displayLanguage;
  final String? businessName;
  final String? businessLogoUrl;

  const ComboOfferShowcase({
    super.key,
    required this.combos,
    required this.pageIndex,
    required this.catTheme,
    required this.theme,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.showComboItemQuantity,
    required this.displayLanguage,
    this.businessName,
    this.businessLogoUrl,
  });

  int get offersPerPage => offersPerPageFor(screenSize);

  static int offersPerPageFor(Size size) => 1;

  @override
  Widget build(BuildContext context) {
    final perPage = offersPerPage;
    final pageCount = (combos.length / perPage).ceil().clamp(1, combos.length);
    final safePage = pageIndex % pageCount;
    final start = safePage * perPage;
    final combo = combos[start];

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
          default:
            return FadeTransition(opacity: animation, child: child);
        }
      },
      child: _PremiumComboFeature(
        key: ValueKey('combo-$safePage'),
        combo: combo,
        theme: theme,
        screenSize: screenSize,
        headingFontScale: headingFontScale,
        nameFontScale: nameFontScale,
        priceFontScale: priceFontScale,
        showPrice: showPrice,
        showProductImage: showProductImage,
        showComboItemQuantity: showComboItemQuantity,
        displayLanguage: displayLanguage,
        businessName: businessName,
        businessLogoUrl: businessLogoUrl,
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// MAIN FEATURE WIDGET
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumComboFeature extends StatelessWidget {
  final MenuItem combo;
  final TvMenuThemeData theme;
  final Size screenSize;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final bool showComboItemQuantity;
  final String displayLanguage;
  final String? businessName;
  final String? businessLogoUrl;

  const _PremiumComboFeature({
    super.key,
    required this.combo,
    required this.theme,
    required this.screenSize,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.showComboItemQuantity,
    required this.displayLanguage,
    required this.businessName,
    required this.businessLogoUrl,
  });

  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  @override
  Widget build(BuildContext context) {
    final heroImage = _absoluteImageUrl(combo.imageUrl) ??
        (combo.comboItems.isNotEmpty
            ? _absoluteImageUrl(combo.comboItems.first.product.imageUrl)
            : null);

    final logoSize = (screenWidth * 0.056).clamp(48.0, 88.0);
    final sideInset = (screenWidth * 0.055).clamp(28.0, 72.0);
    final topInset = (screenHeight * 0.032).clamp(18.0, 40.0);
    final bottomInset = (screenHeight * 0.036).clamp(20.0, 44.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        // â”€â”€ Background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        const Positioned.fill(child: _PremiumBackground()),

        // â”€â”€ Business logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: topInset,
          right: sideInset,
          child: _PremiumBusinessLogo(
            logoUrl: businessLogoUrl,
            businessName: businessName,
            size: logoSize,
          ),
        ),

        // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              sideInset,
              topInset,
              sideInset,
              bottomInset,
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              return _PremiumLayout(
                constraints: constraints,
                combo: combo,
                heroImage: heroImage,
                theme: theme,
                screenSize: screenSize,
                headingFontScale: headingFontScale,
                nameFontScale: nameFontScale,
                priceFontScale: priceFontScale,
                showPrice: showPrice,
                showProductImage: showProductImage,
                showComboItemQuantity: showComboItemQuantity,
                displayLanguage: displayLanguage,
              );
            }),
          ),
        ),

        // â”€â”€ Decorative overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _PremiumOverlayPainter()),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LAYOUT ORCHESTRATOR
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumLayout extends StatelessWidget {
  final BoxConstraints constraints;
  final MenuItem combo;
  final String? heroImage;
  final TvMenuThemeData theme;
  final Size screenSize;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;
  final bool showComboItemQuantity;
  final String displayLanguage;

  const _PremiumLayout({
    required this.constraints,
    required this.combo,
    required this.heroImage,
    required this.theme,
    required this.screenSize,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
    required this.showComboItemQuantity,
    required this.displayLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final cw = constraints.maxWidth;
    final ch = constraints.maxHeight;
    final isCompact = ch < 620;
    final isPortraitPoster = ch > cw * 1.18;

    // â”€â”€ Font sizes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final eyebrowSize = ((cw * 0.022) * headingFontScale).clamp(11.0, 20.0);
    final titleSize =
        ((cw * 0.082) * nameFontScale).clamp(32.0, isCompact ? 70.0 : 112.0);
    final taglineSize = isPortraitPoster
        ? ((cw * 0.052) * headingFontScale).clamp(30.0, 66.0)
        : ((cw * 0.034) * headingFontScale)
            .clamp(16.0, isCompact ? 32.0 : 50.0);
    final footerSize =
        ((cw * 0.018) * headingFontScale).clamp(11.0, isCompact ? 20.0 : 28.0);

    // â”€â”€ Panel heights â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final bottomPanelH = (ch * 0.245).clamp(isCompact ? 130.0 : 148.0, 225.0);
    final footerGap = (ch * 0.010).clamp(4.0, 14.0);
    final itemStripH =
        (bottomPanelH - footerGap - footerSize * 1.15).clamp(72.0, 185.0);

    // â”€â”€ Vertical positions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    final bottomPanelTop = ch - bottomPanelH;
    final defaultHeroTop = tagTop + tagH + (isCompact ? 8.0 : 18.0);
    final heroTop =
        isPortraitPoster ? max(defaultHeroTop, ch * 0.37) : defaultHeroTop;
    final heroRoom =
        (bottomPanelTop - heroTop - (isCompact ? 4.0 : 12.0)).clamp(90.0, ch);
    final heroSize = isPortraitPoster
        ? min(cw * 0.58, heroRoom).clamp(340.0, 540.0)
        : min(
            min(cw * (isCompact ? 0.33 : 0.40), heroRoom),
            (screenSize.height * 0.34).clamp(210.0, 350.0),
          ).clamp(112.0, 350.0);
    final heroLeft = (cw - heroSize) / 2;
    final priceBadgeSize =
        min((cw * 0.105).clamp(72.0, 140.0), heroSize * 0.48);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // â”€â”€ Eyebrow label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: eyebrowTop,
          left: 0,
          right: 0,
          height: eyebrowH,
          child:
              _EyebrowLabel(fontSize: eyebrowSize, language: displayLanguage),
        ),

        // â”€â”€ Gold divider line â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: dividerTop,
          left: cw * 0.14,
          right: cw * 0.14,
          height: dividerH,
          child: CustomPaint(painter: _GoldDividerPainter()),
        ),

        // â”€â”€ Combo name â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: titleTop,
          left: cw * 0.06,
          right: cw * 0.06,
          height: titleH,
          child: _GoldTitleText(text: combo.name, fontSize: titleSize),
        ),

        // â”€â”€ Today's tagline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: tagTop,
          left: 0,
          right: 0,
          height: tagH,
          child: _TaglineText(fontSize: taglineSize, language: displayLanguage),
        ),

        // â”€â”€ Hero dish + price burst â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          left: heroLeft,
          top: heroTop,
          width: heroSize,
          height: heroSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _PremiumHeroDish(
                  imageUrl: heroImage,
                  size: heroSize,
                  showProductImage: showProductImage,
                ),
              ),
              if (showPrice)
                Positioned(
                  right: heroSize * 0.02,
                  bottom: heroSize * 0.10,
                  child: _PremiumPriceBadge(
                    price: combo.price,
                    originalPrice: _comboDisplayOriginalPrice(combo),
                    size: priceBadgeSize,
                    fontSize: ((screenSize.width * 0.027) * priceFontScale)
                        .clamp(20.0, 44.0),
                  ),
                ),
            ],
          ),
        ),

        // â”€â”€ Bottom panel: item strip + tagline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomPanelH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _PremiumItemStrip(
                items: combo.comboItems,
                combo: combo,
                maxWidth: cw * 0.90,
                showProductImage: showProductImage,
                showPrice: showPrice,
                showComboItemQuantity: showComboItemQuantity,
                theme: theme,
                maxHeight: itemStripH,
              ),
              SizedBox(height: footerGap),
              _FooterTagline(fontSize: footerSize, language: displayLanguage),
            ],
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BACKGROUND
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: _PremiumTokens.bgDeep,
      child: CustomPaint(painter: _PremiumBackgroundPainter()),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  const _PremiumBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Deep gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF151009),
            Color(0xFF0D0A07),
            Color(0xFF100C09),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Radial warm glow (top-centre â€” light source)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.7),
        radius: 0.7,
        colors: [
          const Color(0xFFD4A855).withValues(alpha: 0.11),
          const Color(0xFFD4A855).withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Subtle bottom crimson warmth
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.2),
        radius: 0.7,
        colors: [
          const Color(0xFFBF2B2B).withValues(alpha: 0.14),
          const Color(0xFFBF2B2B).withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bottomGlow);

    // Thin horizontal scan-line texture (every ~6px)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.014)
      ..strokeWidth = 0.5;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Bottom panel â€” frosted dark strip
    final panelTop = size.height * 0.73;
    final panelPath = Path()
      ..moveTo(0, panelTop + size.height * 0.06)
      ..cubicTo(
        size.width * 0.22,
        panelTop - size.height * 0.04,
        size.width * 0.68,
        panelTop + size.height * 0.03,
        size.width,
        panelTop,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      panelPath,
      Paint()..color = const Color(0xFF1A1410).withValues(alpha: 0.92),
    );
    // Gold rim on panel edge
    final rimPaint = Paint()
      ..color = const Color(0xFFD4A855).withValues(alpha: 0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final rimPath = Path()
      ..moveTo(0, panelTop + size.height * 0.06)
      ..cubicTo(
        size.width * 0.22,
        panelTop - size.height * 0.04,
        size.width * 0.68,
        panelTop + size.height * 0.03,
        size.width,
        panelTop,
      );
    canvas.drawPath(rimPath, rimPaint);

    // Fine corner ornaments
    _drawCornerOrnament(canvas, Offset(0, 0), size, 0, false);
    _drawCornerOrnament(canvas, Offset(size.width, 0), size, 1, false);
  }

  void _drawCornerOrnament(
      Canvas canvas, Offset origin, Size size, int corner, bool bottom) {
    final l = (size.width * 0.06).clamp(28.0, 56.0);
    final paint = Paint()
      ..color = const Color(0xFFD4A855).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final dx = corner == 0 ? 1.0 : -1.0;
    final sx = corner == 0 ? origin.dx + 18 : origin.dx - 18;
    final sy = origin.dy + 18;

    canvas.drawLine(Offset(sx, sy), Offset(sx + dx * l, sy), paint);
    canvas.drawLine(Offset(sx, sy), Offset(sx, sy + l), paint);
    // small inner L
    canvas.drawLine(
        Offset(sx + dx * 8, sy + 8), Offset(sx + dx * 22, sy + 8), paint);
    canvas.drawLine(
        Offset(sx + dx * 8, sy + 8), Offset(sx + dx * 8, sy + 22), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// OVERLAY PAINTER (subtle grain + vignette)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumOverlayPainter extends CustomPainter {
  const _PremiumOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Vignette
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.38),
          ],
          stops: const [0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Decorative side rules (vertical gold lines)
    final rulePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4A855).withValues(alpha: 0.0),
          const Color(0xFFD4A855).withValues(alpha: 0.22),
          const Color(0xFFD4A855).withValues(alpha: 0.0),
        ],
        stops: const [0.1, 0.45, 0.9],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.035, 0),
      Offset(size.width * 0.035, size.height),
      rulePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.965, 0),
      Offset(size.width * 0.965, size.height),
      rulePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BUSINESS LOGO
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumBusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final String? businessName;
  final double size;

  const _PremiumBusinessLogo({
    required this.logoUrl,
    required this.businessName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _absoluteImageUrl(logoUrl);
    final name = businessName?.trim();

    return SizedBox(
      width: size,
      height: size,
      child: logo != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.18),
              child: CachedNetworkImage(
                imageUrl: logo,
                width: size,
                height: size,
                fit: BoxFit.contain,
                placeholder: (_, __) => _GoldLogoFallback(size: size),
                errorWidget: (_, __, ___) => _GoldLogoFallback(size: size),
              ),
            )
          : _GoldLogoFallback(size: size, label: name),
    );
  }
}

class _GoldLogoFallback extends StatelessWidget {
  final double size;
  final String? label;

  const _GoldLogoFallback({required this.size, this.label});

  @override
  Widget build(BuildContext context) {
    final text = (label?.trim().isNotEmpty ?? false)
        ? label!.trim().characters.first.toUpperCase()
        : 'T';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _PremiumTokens.bgSurface,
        border: Border.all(color: _PremiumTokens.goldDim, width: 1.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.cormorantGaramond(
            color: _PremiumTokens.goldLight,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// EYEBROW LABEL  ("COMBO SPECIAL" / localized)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// GOLD DIVIDER
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// COMBO TITLE  (gold embossed)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GoldTitleText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _GoldTitleText({required this.text, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 980,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Shadow layer
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
            // Gold foreground
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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// TAGLINE  ("Today's Best Deal" / localized)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// HERO DISH
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
          // Plate glow
          Positioned(
            bottom: size * 0.05,
            child: Container(
              width: size * 0.62,
              height: size * 0.12,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(size),
                boxShadow: [
                  BoxShadow(
                    color: _PremiumTokens.goldPrimary.withValues(alpha: 0.20),
                    blurRadius: 38,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          // Ring ornament behind dish
          Positioned(
            top: size * 0.04,
            child: CustomPaint(
              size: Size(size * 0.86, size * 0.86),
              painter: _RingOrnamentPainter(),
            ),
          ),
          // Dish image
          Positioned(
            top: size * 0.04,
            left: size * 0.04,
            right: size * 0.04,
            bottom: size * 0.04,
            child: !showProductImage || imageUrl == null
                ? const _PremiumImageFallback(label: 'COMBO')
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const _PremiumImageFallback(label: 'COMBO'),
                    errorWidget: (_, __, ___) =>
                        const _PremiumImageFallback(label: 'COMBO'),
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

    // Outer ring
    paint.color = _PremiumTokens.goldPrimary.withValues(alpha: 0.18);
    canvas.drawCircle(center, radius, paint);

    // Dashed inner ring
    paint.color = _PremiumTokens.goldPrimary.withValues(alpha: 0.10);
    paint.strokeWidth = 0.6;
    canvas.drawCircle(center, radius * 0.84, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PRICE BADGE  (gold starburst, dark text)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumPriceBadge extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double size;
  final double fontSize;

  const _PremiumPriceBadge({
    required this.price,
    required this.originalPrice,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final showOriginal = originalPrice != null && originalPrice! > price;
    return CustomPaint(
      painter: const _GoldBurstPainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showOriginal)
                Text(
                  'Rs ${originalPrice!.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    color: _PremiumTokens.priceText.withValues(alpha: 0.58),
                    fontSize: fontSize * 0.46,
                    height: 0.86,
                    decoration: TextDecoration.lineThrough,
                    decorationColor:
                        _PremiumTokens.priceText.withValues(alpha: 0.58),
                    decorationThickness: 1.8,
                  ),
                ),
              Text(
                'Rs\n${price.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  color: _PremiumTokens.priceText,
                  fontSize: showOriginal ? fontSize * 0.90 : fontSize,
                  height: 0.82,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldBurstPainter extends CustomPainter {
  const _GoldBurstPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.86;
    const points = 28;

    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final angle = -pi / 2 + i * pi / points;
      final radius = i.isEven ? outer : inner;
      final pt = center + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();

    // Gold fill with gradient
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: const [
            Color(0xFFF5D98A),
            Color(0xFFD4A855),
            Color(0xFFB8882E),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & size),
    );

    // Thin dark stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldBurstPainter _) => false;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ITEM STRIP
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PremiumItemStrip extends StatelessWidget {
  final List<ComboOfferItem> items;
  final MenuItem combo;
  final double maxWidth;
  final bool showProductImage;
  final bool showPrice;
  final bool showComboItemQuantity;
  final TvMenuThemeData theme;
  final double maxHeight;

  const _PremiumItemStrip({
    required this.items,
    required this.combo,
    required this.maxWidth,
    required this.showProductImage,
    required this.showPrice,
    required this.showComboItemQuantity,
    required this.theme,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items.isNotEmpty
        ? items.take(4).toList()
        : [ComboOfferItem(id: 0, quantity: 1, product: combo)];

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        height: maxHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final item in displayItems)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _PremiumItemTile(
                    item: item,
                    showProductImage: showProductImage,
                    showPrice: showPrice,
                    showComboItemQuantity: showComboItemQuantity,
                    theme: theme,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumItemTile extends StatelessWidget {
  final ComboOfferItem item;
  final bool showProductImage;
  final bool showPrice;
  final bool showComboItemQuantity;
  final TvMenuThemeData theme;

  const _PremiumItemTile({
    required this.item,
    required this.showProductImage,
    required this.showPrice,
    required this.showComboItemQuantity,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _absoluteImageUrl(item.product.imageUrl);
    final price = _comboItemUnitPrice(item);

    return LayoutBuilder(builder: (context, constraints) {
      final detail =
          _comboItemDetail(item, showQuantity: showComboItemQuantity);
      final detailHeight = detail.isNotEmpty ? 14.0 : 0.0;
      final nameHeight = constraints.maxHeight < 120 ? 26.0 : 32.0;
      final gapH = constraints.maxHeight < 120 ? 4.0 : 6.0;
      final imageH =
          max(40.0, constraints.maxHeight - nameHeight - gapH - detailHeight);
      final imageSize = min(constraints.maxWidth.clamp(64.0, 140.0),
          (imageH / 0.78).clamp(52.0, 140.0));
      final nameFontSize = min(constraints.maxWidth.clamp(14.0, 26.0),
          constraints.maxHeight < 120 ? 18.0 : 26.0);
      final detailFontSz = min(constraints.maxWidth.clamp(9.0, 13.0),
          constraints.maxHeight < 120 ? 10.0 : 13.0);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: imageSize * 0.78,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Glass card backing
                Container(
                  width: imageSize,
                  height: imageSize * 0.78,
                  decoration: BoxDecoration(
                    color: _PremiumTokens.bgGlass,
                    borderRadius: BorderRadius.circular(imageSize * 0.14),
                    border: Border.all(
                      color: _PremiumTokens.goldPrimary.withValues(alpha: 0.14),
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(imageSize * 0.14),
                    child: !showProductImage || imageUrl == null
                        ? const _PremiumImageFallback(label: 'ITEM')
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) =>
                                const _PremiumImageFallback(label: 'ITEM'),
                            errorWidget: (_, __, ___) =>
                                const _PremiumImageFallback(label: 'ITEM'),
                          ),
                  ),
                ),
                if (showPrice)
                  Positioned(
                    right: 0,
                    top: -6,
                    child: _SmallGoldBadge(price: price),
                  ),
              ],
            ),
          ),
          SizedBox(height: gapH),
          SizedBox(
            width: double.infinity,
            height: nameHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                item.product.name.toUpperCase(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  color: _PremiumTokens.goldLight,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          if (detail.isNotEmpty)
            Text(
              detail,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: _PremiumTokens.textMuted.withValues(alpha: 0.80),
                fontSize: detailFontSz,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
    });
  }
}

class _SmallGoldBadge extends StatelessWidget {
  final double price;

  const _SmallGoldBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _GoldBurstPainter(),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Center(
          child: Text(
            'Rs\n${price.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              color: _PremiumTokens.priceText,
              fontSize: 15,
              height: 0.84,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// FOOTER TAGLINE
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// IMAGE FALLBACK
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
            color: _PremiumTokens.goldDim.withValues(alpha: 0.60),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// LOCALIZATION  (unchanged logic, extended with new keys)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _comboLocalized(String language, String key) {
  if (_isMalayalam(language)) {
    return switch (key) {
      'eyebrow' => 'കോംബോ സ്പെഷ്യൽ',
      'headline' => 'അടിപൊളി ഫുഡ് കഴിച്ചാലോ?',
      'todaysBestDeal' => 'ഇന്നത്തെ ബെസ്റ്റ് ഡീൽ',
      'serveGreatness' => 'രുചിയുടെ സന്തോഷം',
      _ => key,
    };
  }
  return switch (key) {
    'eyebrow' => 'COMBO SPECIAL',
    'headline' => 'SUPER DELICIOUS FOOD',
    'todaysBestDeal' => "Today's Best Deal",
    'serveGreatness' => 'WE SERVE YOU GREATNESS',
    _ => key,
  };
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PRICE HELPERS  (identical to original)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

String _comboItemDetail(ComboOfferItem item, {required bool showQuantity}) {
  if (!showQuantity) return '';
  final selectedLabel = item.variantLabel?.trim();
  final quantity = 'x${item.quantity}';
  String withQuantity(String value) =>
      value.isEmpty ? quantity : '$value  $quantity';

  if (selectedLabel != null && selectedLabel.isNotEmpty) {
    return withQuantity(selectedLabel);
  }
  if (item.variantPrice != null) {
    for (final variant in item.product.priceVariants) {
      if ((variant.price - item.variantPrice!).abs() < 0.01 &&
          variant.label.trim().isNotEmpty) {
        return withQuantity(variant.label.trim());
      }
    }
  }
  if (item.product.priceVariants.isNotEmpty) {
    final fullVariant = item.product.priceVariants
        .where((v) => v.label.trim().toLowerCase() == 'full')
        .cast<PriceVariant?>()
        .firstWhere((_) => true, orElse: () => null);
    if (fullVariant != null) return withQuantity(fullVariant.label.trim());
    final fallback = item.product.priceVariants.last.label.trim();
    if (fallback.isNotEmpty) return withQuantity(fallback);
  }
  return quantity;
}

double _comboDisplayOriginalPrice(MenuItem combo) {
  final computed = _comboOriginalPrice(combo);
  final payloadOriginal = combo.originalPrice ?? 0;
  return max(payloadOriginal, computed);
}

double _comboOriginalPrice(MenuItem combo) => combo.comboItems.fold<double>(
    0, (total, item) => total + _comboItemUnitPrice(item) * item.quantity);

double _comboItemUnitPrice(ComboOfferItem item) {
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
        .where((v) => v.label.trim().toLowerCase() == 'full')
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
