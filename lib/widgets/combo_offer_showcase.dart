import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

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

  static int offersPerPageFor(Size size) {
    return 1;
  }

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
      child: _ComboOfferFeature(
        key: ValueKey('combo-$safePage'),
        combo: combo,
        theme: theme,
        screenWidth: screenSize.width,
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

class _ComboOfferFeature extends StatelessWidget {
  final MenuItem combo;
  final TvMenuThemeData theme;
  final double screenWidth;
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

  const _ComboOfferFeature({
    super.key,
    required this.combo,
    required this.theme,
    required this.screenWidth,
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

  @override
  Widget build(BuildContext context) {
    final heroImage = _absoluteImageUrl(combo.imageUrl) ??
        (combo.comboItems.isNotEmpty
            ? _absoluteImageUrl(combo.comboItems.first.product.imageUrl)
            : null);
    final logoSize = (screenWidth * 0.056).clamp(54.0, 96.0);
    final sideInset = (screenWidth * 0.055).clamp(30.0, 80.0);
    final topInset = (screenSize.height * 0.032).clamp(20.0, 42.0);
    final bottomInset = (screenSize.height * 0.040).clamp(22.0, 46.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _ComboPosterBackground()),
        Positioned(
          top: topInset,
          right: sideInset,
          child: _ComboBusinessLogo(
            logoUrl: businessLogoUrl,
            businessName: businessName,
            size: logoSize,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              sideInset,
              topInset,
              sideInset,
              bottomInset,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentHeight = constraints.maxHeight;
                final contentWidth = constraints.maxWidth;
                final isCompact = contentHeight < 620;
                final isPortraitPoster = contentHeight > contentWidth * 1.18;
                final headlineSize = ((contentWidth * 0.060) * headingFontScale)
                    .clamp(30.0, isCompact ? 62.0 : 86.0);
                final titleSize = ((contentWidth * 0.082) * nameFontScale)
                    .clamp(34.0, isCompact ? 74.0 : 118.0);
                final dealSize = isPortraitPoster
                    ? ((contentWidth * 0.052) * headingFontScale)
                        .clamp(32.0, 70.0)
                    : ((contentWidth * 0.034) * headingFontScale)
                        .clamp(18.0, isCompact ? 34.0 : 52.0);
                final bottomPanelHeight = (contentHeight * 0.245)
                    .clamp(isCompact ? 132.0 : 150.0, 230.0);
                final footerGap =
                    (contentHeight * 0.012).clamp(4.0, isCompact ? 10.0 : 16.0);
                final footerFontSize =
                    ((contentWidth * 0.020) * headingFontScale)
                        .clamp(12.0, isCompact ? 22.0 : 32.0);
                final itemStripHeight =
                    (bottomPanelHeight - footerGap - footerFontSize * 1.15)
                        .clamp(76.0, 190.0);

                const headlineTop = 0.0;
                final headlineHeight = headlineSize * 1.58;
                final titleTop =
                    headlineTop + headlineHeight + (isCompact ? 6.0 : 12.0);
                final titleHeight = titleSize * 1.08;
                final defaultDealTop =
                    titleTop + titleHeight + (isCompact ? 5.0 : 12.0);
                final dealTop = isPortraitPoster
                    ? max(defaultDealTop, contentHeight * 0.245)
                    : defaultDealTop;
                final dealHeight = dealSize * (isPortraitPoster ? 1.18 : 1.1);
                final bottomPanelTop = contentHeight - bottomPanelHeight;
                final defaultHeroTop =
                    dealTop + dealHeight + (isCompact ? 8.0 : 16.0);
                final heroTop = isPortraitPoster
                    ? max(defaultHeroTop, contentHeight * 0.37)
                    : defaultHeroTop;
                final heroRoom =
                    (bottomPanelTop - heroTop - (isCompact ? 4.0 : 12.0))
                        .clamp(96.0, contentHeight);
                final heroSize = isPortraitPoster
                    ? min(contentWidth * 0.58, heroRoom).clamp(360.0, 560.0)
                    : min(
                        min(contentWidth * (isCompact ? 0.33 : 0.40), heroRoom),
                        (screenSize.height * 0.34).clamp(220.0, 360.0),
                      ).clamp(118.0, 360.0);
                final heroLeft = (contentWidth - heroSize) / 2;
                final priceBadgeSize = min(
                  (contentWidth * 0.105).clamp(76.0, 148.0),
                  heroSize * 0.48,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: headlineTop,
                      left: 0,
                      right: 0,
                      height: headlineHeight,
                      child: _ComboPosterHeadline(
                        fontSize: headlineSize,
                        language: displayLanguage,
                      ),
                    ),
                    Positioned(
                      top: titleTop,
                      left: contentWidth * 0.08,
                      right: contentWidth * 0.08,
                      height: titleHeight,
                      child: _ComboTitleText(
                        text: combo.name,
                        fontSize: titleSize,
                      ),
                    ),
                    Positioned(
                      top: dealTop,
                      left: 0,
                      right: 0,
                      height: dealHeight,
                      child: Text(
                        _comboLocalized(displayLanguage, 'todaysBestDeal'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: dealSize,
                          height: 1,
                          letterSpacing: 0,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(
                              color: Color(0x99000000),
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: heroLeft,
                      top: heroTop,
                      width: heroSize,
                      height: heroSize,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: _ComboHeroDish(
                              imageUrl: heroImage,
                              size: heroSize,
                              showProductImage: showProductImage,
                            ),
                          ),
                          if (showPrice)
                            Positioned(
                              right: heroSize * 0.02,
                              bottom: heroSize * 0.10,
                              child: _MainPriceBurst(
                                price: combo.price,
                                originalPrice:
                                    _comboDisplayOriginalPrice(combo),
                                size: priceBadgeSize,
                                fontSize:
                                    ((screenWidth * 0.027) * priceFontScale)
                                        .clamp(22.0, 46.0),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: bottomPanelHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ComboItemStrip(
                            items: combo.comboItems,
                            combo: combo,
                            maxWidth: contentWidth * 0.88,
                            showProductImage: showProductImage,
                            showPrice: showPrice,
                            showComboItemQuantity: showComboItemQuantity,
                            theme: theme,
                            maxHeight: itemStripHeight,
                          ),
                          SizedBox(height: footerGap),
                          Text(
                            _comboLocalized(displayLanguage, 'serveGreatness'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.bowlbyOneSc(
                              color: const Color(0xFFE32121),
                              fontSize: footerFontSize,
                              height: 1,
                              letterSpacing: 0,
                              shadows: const [
                                Shadow(
                                  color: Color(0x22000000),
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
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
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ComboPosterDoodlePainter(
                compact: screenSize.height < 620,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ComboBusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final String? businessName;
  final double size;

  const _ComboBusinessLogo({
    required this.logoUrl,
    required this.businessName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final logo = _absoluteImageUrl(logoUrl);
    final name = businessName?.trim();

    return SizedBox(
      height: size,
      child: Center(
        child: logo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.16),
                child: CachedNetworkImage(
                  imageUrl: logo,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => _LogoFallback(size: size),
                  errorWidget: (_, __, ___) => _LogoFallback(size: size),
                ),
              )
            : _LogoFallback(size: size, label: name),
      ),
    );
  }
}

class _LogoFallback extends StatelessWidget {
  final double size;
  final String? label;

  const _LogoFallback({required this.size, this.label});

  @override
  Widget build(BuildContext context) {
    final text = (label?.trim().isNotEmpty ?? false)
        ? label!.trim().characters.first.toUpperCase()
        : 'T';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white, width: 2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.bowlbyOneSc(
            color: Colors.white,
            fontSize: size * 0.44,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ComboHeroDish extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showProductImage;

  const _ComboHeroDish({
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
          Positioned(
            bottom: size * 0.06,
            child: Container(
              width: size * 0.56,
              height: size * 0.10,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(size),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.92,
            height: size * 0.92,
            clipBehavior: Clip.none,
            decoration: const BoxDecoration(),
            child: !showProductImage || imageUrl == null
                ? const _PosterImageFallback(label: 'COMBO')
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const _PosterImageFallback(label: 'COMBO'),
                    errorWidget: (_, __, ___) =>
                        const _PosterImageFallback(label: 'COMBO'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComboPosterHeadline extends StatelessWidget {
  final double fontSize;
  final String language;

  const _ComboPosterHeadline({
    required this.fontSize,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (_isMalayalam(language)) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _comboLocalized(language, 'headline'),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.notoSansMalayalam(
            color: Colors.white,
            fontSize: fontSize,
            height: 1.02,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                color: Color(0x77000000),
                offset: Offset(0, 5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SUPER',
          textAlign: TextAlign.center,
          style: GoogleFonts.bowlbyOneSc(
            color: Colors.white,
            fontSize: fontSize * 0.74,
            height: 0.92,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0x77000000),
                offset: Offset(0, 5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Text(
          'DELICIOUS FOOD',
          textAlign: TextAlign.center,
          style: GoogleFonts.bowlbyOneSc(
            color: Colors.white,
            fontSize: fontSize,
            height: 0.88,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                color: Color(0x77000000),
                offset: Offset(0, 5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _comboLocalized(String language, String key) {
  if (_isMalayalam(language)) {
    return switch (key) {
      'headline' => 'അടിപൊളി ഫുഡ് കഴിച്ചാലോ?',
      'todaysBestDeal' => 'ഇന്നത്തെ ബെസ്റ്റ് ഡീൽ',
      'serveGreatness' => 'രുചിയുടെ സന്തോഷം',
      _ => key,
    };
  }
  return switch (key) {
    'headline' => 'SUPER DELICIOUS FOOD',
    'todaysBestDeal' => "Today's Best Deal",
    'serveGreatness' => 'WE SERVE YOU GREATNESS',
    _ => key,
  };
}

class _ComboTitleText extends StatelessWidget {
  final String text;
  final double fontSize;

  const _ComboTitleText({
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
              style: GoogleFonts.bowlbyOneSc(
                color: const Color(0xFF2A0505).withValues(alpha: 0.42),
                fontSize: fontSize,
                height: 0.86,
                letterSpacing: 0,
              ),
            ),
            Transform.translate(
              offset: Offset(-fontSize * 0.035, -fontSize * 0.04),
              child: Text(
                text.toUpperCase(),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bowlbyOneSc(
                  color: Colors.white,
                  fontSize: fontSize,
                  height: 0.86,
                  letterSpacing: 0,
                  shadows: const [
                    Shadow(
                      color: Color(0x88000000),
                      offset: Offset(0, 6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainPriceBurst extends StatelessWidget {
  final double price;
  final double? originalPrice;
  final double size;
  final double fontSize;

  const _MainPriceBurst({
    required this.price,
    required this.originalPrice,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final showOriginal = originalPrice != null && originalPrice! > price;

    return CustomPaint(
      painter: const _BurstPainter(color: Color(0xFFFF2727)),
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
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: fontSize * 0.48,
                    height: 0.86,
                    letterSpacing: 0,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white,
                    decorationThickness: 2,
                  ),
                ),
              Text(
                'Rs\n${price.toStringAsFixed(0)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: showOriginal ? fontSize * 0.92 : fontSize,
                  height: 0.82,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComboItemStrip extends StatelessWidget {
  final List<ComboOfferItem> items;
  final MenuItem combo;
  final double maxWidth;
  final bool showProductImage;
  final bool showPrice;
  final bool showComboItemQuantity;
  final TvMenuThemeData theme;
  final double maxHeight;

  const _ComboItemStrip({
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
        : [
            ComboOfferItem(
              id: 0,
              quantity: 1,
              product: combo,
            )
          ];

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
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _ComboPosterItemTile(
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

class _ComboPosterItemTile extends StatelessWidget {
  final ComboOfferItem item;
  final bool showProductImage;
  final bool showPrice;
  final bool showComboItemQuantity;
  final TvMenuThemeData theme;

  const _ComboPosterItemTile({
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final detail = _comboItemDetail(
          item,
          showQuantity: showComboItemQuantity,
        );
        final detailHeight = detail.isNotEmpty ? 15.0 : 0.0;
        final nameHeight = constraints.maxHeight < 120 ? 28.0 : 34.0;
        final gapHeight = constraints.maxHeight < 120 ? 4.0 : 6.0;
        final availableImageHeight = max(42.0,
            constraints.maxHeight - nameHeight - gapHeight - detailHeight);
        final imageSize = min(
          constraints.maxWidth.clamp(68.0, 150.0),
          (availableImageHeight / 0.78).clamp(56.0, 150.0),
        );
        final nameFontSize = min(
          constraints.maxWidth.clamp(16.0, 28.0),
          constraints.maxHeight < 120 ? 20.0 : 28.0,
        );
        final detailFontSize = min(
          constraints.maxWidth.clamp(10.0, 14.0),
          constraints.maxHeight < 120 ? 11.0 : 14.0,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: imageSize * 0.78,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: imageSize,
                    height: imageSize * 0.78,
                    child: !showProductImage || imageUrl == null
                        ? const _PosterImageFallback(label: 'ITEM')
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, __) =>
                                const _PosterImageFallback(label: 'ITEM'),
                            errorWidget: (_, __, ___) =>
                                const _PosterImageFallback(label: 'ITEM'),
                          ),
                  ),
                  if (showPrice)
                    Positioned(
                      right: 0,
                      top: -8,
                      child: _SmallPriceBurst(price: price),
                    ),
                ],
              ),
            ),
            SizedBox(height: gapHeight),
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
                  style: GoogleFonts.bowlbyOneSc(
                    color: const Color(0xFFE32121),
                    fontSize: nameFontSize,
                    height: 1,
                    letterSpacing: 0,
                    shadows: const [
                      Shadow(
                        color: Color(0x22000000),
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
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
                  color: const Color(0xFF2A2A2A).withValues(alpha: 0.72),
                  fontSize: detailFontSize,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SmallPriceBurst extends StatelessWidget {
  final double price;

  const _SmallPriceBurst({required this.price});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _BurstPainter(color: Color(0xFFFFD21A)),
      child: SizedBox(
        width: 54,
        height: 54,
        child: Center(
          child: Text(
            'Rs\n${price.toStringAsFixed(0)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              color: const Color(0xFFE43115),
              fontSize: 17,
              height: 0.82,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterImageFallback extends StatelessWidget {
  final String label;

  const _PosterImageFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF26110D).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.bowlbyOneSc(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 16,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _ComboPosterBackground extends StatelessWidget {
  const _ComboPosterBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFB91414),
      child: CustomPaint(painter: _ComboPosterBackgroundPainter()),
    );
  }
}

class _ComboPosterBackgroundPainter extends CustomPainter {
  const _ComboPosterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC51818),
            Color(0xFFA90F13),
            Color(0xFF8D0A0E),
          ],
        ).createShader(rect),
    );

    final brickPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1.4;
    final brickHeight = (size.height * 0.055).clamp(34.0, 58.0);
    final brickWidth = (size.width * 0.125).clamp(88.0, 150.0);
    final redAreaHeight = size.height * 0.70;
    for (var y = 0.0; y < redAreaHeight; y += brickHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), brickPaint);
      final offset = ((y / brickHeight).round().isEven) ? 0.0 : brickWidth / 2;
      for (var x = -brickWidth + offset; x < size.width; x += brickWidth) {
        canvas.drawLine(Offset(x, y), Offset(x, y + brickHeight), brickPaint);
      }
    }

    final whiteBase = Path()
      ..moveTo(0, size.height * 0.63)
      ..cubicTo(
        size.width * 0.26,
        size.height * 0.70,
        size.width * 0.42,
        size.height * 0.55,
        size.width,
        size.height * 0.61,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(whiteBase, Paint()..color = const Color(0xFFF9F6F0));

    final rim = Paint()
      ..color = const Color(0xFFE32121)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final rimPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.80)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.82,
        size.width * 0.38,
        size.height * 0.80,
      )
      ..moveTo(size.width * 0.62, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.77,
        size.height * 0.80,
        size.width * 0.92,
        size.height * 0.82,
      );
    canvas.drawPath(rimPath, rim);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ComboPosterDoodlePainter extends CustomPainter {
  final bool compact;

  const _ComboPosterDoodlePainter({
    this.compact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final leftArrowTipX = compact ? 0.33 : 0.23;

    void drawSplash(Offset center, double scale) {
      for (final angle in [-0.8, -0.25, 0.35, 0.9]) {
        final start = center + Offset(cos(angle), sin(angle)) * 10 * scale;
        final end = center + Offset(cos(angle), sin(angle)) * 32 * scale;
        canvas.drawLine(start, end, paint);
      }
      canvas.drawCircle(
          center + Offset(38 * scale, -4 * scale), 4 * scale, paint);
    }

    final leftX = compact ? 0.30 : 0.22;
    final rightX = compact ? 0.70 : 0.78;
    final splashScale = compact ? 0.74 : 1.0;

    drawSplash(
      Offset(size.width * leftX, size.height * 0.36),
      splashScale,
    );
    drawSplash(
      Offset(size.width * rightX, size.height * 0.34),
      splashScale * 0.86,
    );

    final arrowLeft = Path()
      ..moveTo(size.width * (compact ? 0.27 : 0.18), size.height * 0.31)
      ..quadraticBezierTo(
        size.width * (compact ? 0.21 : 0.13),
        size.height * 0.38,
        size.width * leftArrowTipX,
        size.height * 0.45,
      )
      ..moveTo(size.width * leftArrowTipX, size.height * 0.45)
      ..lineTo(size.width * (compact ? 0.28 : 0.18), size.height * 0.43)
      ..moveTo(size.width * leftArrowTipX, size.height * 0.45)
      ..lineTo(size.width * (compact ? 0.30 : 0.21), size.height * 0.40);
    canvas.drawPath(arrowLeft, paint);

    final arrowRight = Path()
      ..moveTo(size.width * (compact ? 0.73 : 0.79), size.height * 0.29)
      ..quadraticBezierTo(
        size.width * (compact ? 0.79 : 0.91),
        size.height * 0.35,
        size.width * (compact ? 0.67 : 0.78),
        size.height * 0.47,
      )
      ..moveTo(size.width * (compact ? 0.67 : 0.78), size.height * 0.47)
      ..lineTo(size.width * (compact ? 0.73 : 0.84), size.height * 0.44)
      ..moveTo(size.width * (compact ? 0.67 : 0.78), size.height * 0.47)
      ..lineTo(size.width * (compact ? 0.71 : 0.82), size.height * 0.40);
    canvas.drawPath(arrowRight, paint);
  }

  @override
  bool shouldRepaint(covariant _ComboPosterDoodlePainter oldDelegate) =>
      oldDelegate.compact != compact;
}

class _BurstPainter extends CustomPainter {
  final Color color;

  const _BurstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.86;
    final path = Path();
    const points = 28;
    for (var i = 0; i < points * 2; i++) {
      final angle = -1.5708 + i * 3.14159 / points;
      final radius = i.isEven ? outer : inner;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _comboItemDetail(
  ComboOfferItem item, {
  required bool showQuantity,
}) {
  if (!showQuantity) return '';

  final selectedLabel = item.variantLabel?.trim();
  final quantity = 'x${item.quantity}';
  String withQuantity(String value) {
    return value.isEmpty ? quantity : '$value  $quantity';
  }

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
        .where((variant) => variant.label.trim().toLowerCase() == 'full')
        .cast<PriceVariant?>()
        .firstWhere((variant) => variant != null, orElse: () => null);
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

double _comboOriginalPrice(MenuItem combo) {
  return combo.comboItems.fold<double>(
    0,
    (total, item) => total + _comboItemUnitPrice(item) * item.quantity,
  );
}

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
        .where((variant) => variant.label.trim().toLowerCase() == 'full')
        .cast<PriceVariant?>()
        .firstWhere((variant) => variant != null, orElse: () => null);
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
  return 'http://192.168.29.184:4002/$path';
}
