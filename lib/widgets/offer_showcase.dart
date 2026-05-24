import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

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
        businessName: businessName,
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
  final String? businessName;
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
    required this.businessName,
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
      );
    }

    final width = screenSize.width;
    final sideInset = (width * 0.048).clamp(30.0, 78.0);
    final topInset = (screenSize.height * 0.036).clamp(22.0, 46.0);
    final titleSize = ((width * 0.044) * nameFontScale).clamp(34.0, 74.0);
    final headingSize = ((width * 0.026) * headingFontScale).clamp(22.0, 44.0);
    const offerAccent = Color(0xFFE32121);

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF08090D)),
      child: SafeArea(
        child: CustomPaint(
          painter: const _DottedGridPainter(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(sideInset, topInset, sideInset, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _offerLocalized(displayLanguage, 'discountOffer'),
                        style: GoogleFonts.dmSans(
                          color: offerAccent,
                          fontSize: headingSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    _BusinessLogo(
                      logoUrl: businessLogoUrl,
                      businessName: businessName,
                      size: (width * 0.046).clamp(46.0, 78.0),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 0),
                child: Text(
                  offer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    height: 0.96,
                  ),
                ),
              ),
              if (offer.description?.isNotEmpty == true) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(sideInset, 8, sideInset, 0),
                  child: Text(
                    offer.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFB9BBC6),
                      fontSize: headingSize * 0.66,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sideInset,
                    (screenSize.height * 0.032).clamp(18.0, 34.0),
                    sideInset,
                    topInset,
                  ),
                  child: _OfferItemGrid(
                    items: offer.comboItems,
                    offerType: offer.offerType ?? 'discount',
                    showPrice: showPrice,
                    showProductImage: showProductImage,
                    priceFontScale: priceFontScale,
                    theme: theme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  const _FreeOfferPoster({
    required this.offer,
    required this.item,
    required this.screenSize,
    required this.showProductImage,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.displayLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final width = screenSize.width;
    final height = screenSize.height;
    final isWidePoster = width / height > 1.35;
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
    final sideInset = (width * 0.055).clamp(34.0, 86.0);
    final topInset = (height * 0.035).clamp(22.0, 46.0);
    final titleSize = isWidePoster
        ? ((height * 0.048) * nameFontScale).clamp(30.0, 54.0)
        : ((width * 0.038) * nameFontScale).clamp(30.0, 64.0);
    final offerWordSize = isWidePoster
        ? ((height * 0.104) * priceFontScale).clamp(70.0, 116.0)
        : ((width * 0.092) * priceFontScale).clamp(72.0, 150.0);
    final numberSize = isWidePoster
        ? ((height * 0.184) * priceFontScale).clamp(118.0, 202.0)
        : ((width * 0.16) * priceFontScale).clamp(130.0, 260.0);
    final detailSize = isWidePoster
        ? ((height * 0.028) * headingFontScale).clamp(18.0, 30.0)
        : ((width * 0.020) * headingFontScale).clamp(20.0, 36.0);
    final panelTop = isWidePoster ? height * 0.285 : height * 0.31;
    final panelBottom = isWidePoster ? height * 0.245 : height * 0.29;
    final panelLeft = isWidePoster ? width * 0.20 : width * 0.11;
    final panelRight = isWidePoster ? width * 0.20 : width * 0.10;
    final textLeft = isWidePoster ? width * 0.265 : width * 0.17;
    final textRight = isWidePoster ? width * 0.265 : width * 0.16;
    final textTop = isWidePoster ? height * 0.325 : height * 0.355;
    final headlineHeight = height * 0.225;
    final topImageSize =
        (isWidePoster ? height * 0.32 : height * 0.34).clamp(220.0, 390.0);
    final bottomImageSize =
        (isWidePoster ? height * 0.34 : height * 0.36).clamp(230.0, 420.0);

    return Container(
      color: const Color(0xFF281C42),
      child: SafeArea(
        child: Padding(
          padding:
              EdgeInsets.fromLTRB(sideInset, topInset, sideInset, topInset),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF8E1F),
                    Color(0xFFE85C1B),
                    Color(0xFFFFB328),
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _OfferPatternText(),
                  Positioned.fill(
                    top: height * 0.22,
                    bottom: height * 0.20,
                    child: const ColoredBox(color: Color(0xFF221B3D)),
                  ),
                  Positioned.fill(
                    top: panelTop,
                    bottom: panelBottom,
                    left: panelLeft,
                    right: panelRight,
                    child: const CustomPaint(
                      painter: _BrushPanelPainter(),
                    ),
                  ),
                  if (isWidePoster)
                    Positioned(
                      top: height * 0.015,
                      left: (width - topImageSize) / 2,
                      width: topImageSize,
                      height: topImageSize,
                      child: _PosterFoodImage(
                        item: posterItem,
                        showProductImage: showProductImage,
                        preferFreeProduct: false,
                      ),
                    )
                  else
                    Positioned(
                      top: -height * 0.05,
                      left: width * 0.22,
                      right: width * 0.22,
                      height: height * 0.34,
                      child: _PosterFoodImage(
                        item: posterItem,
                        showProductImage: showProductImage,
                        preferFreeProduct: false,
                      ),
                    ),
                  if (isWidePoster)
                    Positioned(
                      left: (width - bottomImageSize) / 2,
                      bottom: -height * 0.025,
                      width: bottomImageSize,
                      height: bottomImageSize,
                      child: _PosterFoodImage(
                        item: posterItem,
                        showProductImage: showProductImage,
                        preferFreeProduct: true,
                      ),
                    )
                  else
                    Positioned(
                      left: width * 0.20,
                      right: width * 0.17,
                      bottom: -height * 0.07,
                      height: height * 0.36,
                      child: _PosterFoodImage(
                        item: posterItem,
                        showProductImage: showProductImage,
                        preferFreeProduct: true,
                      ),
                    ),
                  Positioned(
                    left: textLeft,
                    right: textRight,
                    top: textTop,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          offer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isWidePoster)
                          SizedBox(
                            height: headlineHeight,
                            child: _BuyGetHeadline(
                              buyQty: buyQty,
                              freeQty: freeQty,
                              language: displayLanguage,
                              offerWordSize: offerWordSize,
                              numberSize: numberSize,
                            ),
                          )
                        else
                          _BuyGetHeadline(
                            buyQty: buyQty,
                            freeQty: freeQty,
                            language: displayLanguage,
                            offerWordSize: offerWordSize,
                            numberSize: numberSize,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          offerDetail,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: detailSize,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            color: const Color(0xFFFFC928),
            fontWeight: FontWeight.w900,
            height: 0.9,
            shadows: const [
              Shadow(
                  color: Color(0xFF260B0B),
                  offset: Offset(4, 5),
                  blurRadius: 0),
            ],
          )
        : GoogleFonts.dmSans(
            color: const Color(0xFFFFC928),
            fontWeight: FontWeight.w900,
            height: 0.82,
            letterSpacing: 0,
            shadows: const [
              Shadow(
                  color: Color(0xFF260B0B),
                  offset: Offset(4, 5),
                  blurRadius: 0),
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
              Text(isMalayalam ? 'വാങ്ങൂ $buyQty' : 'BUY$buyQty',
                  style: textStyle.copyWith(fontSize: offerWordSize)),
              Text(isMalayalam ? 'നേടൂ' : 'GET',
                  style: textStyle.copyWith(fontSize: offerWordSize * 0.92)),
            ],
          ),
          const SizedBox(width: 16),
          Text(
            '$freeQty',
            style: textStyle.copyWith(fontSize: numberSize),
          ),
        ],
      ),
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
    final imageUrl = product?.imageUrl;

    if (showProductImage && imageUrl?.isNotEmpty == true) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF3A244A),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFFFC928),
        size: 96,
      ),
    );
  }
}

class _OfferPatternText extends StatelessWidget {
  const _OfferPatternText();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth / 4).clamp(180.0, 280.0);
            final tileHeight = (constraints.maxHeight / 3).clamp(120.0, 190.0);
            final columns = (constraints.maxWidth / tileWidth).ceil() + 1;
            final rows = (constraints.maxHeight / tileHeight).ceil() + 1;

            return OverflowBox(
              maxWidth: constraints.maxWidth + tileWidth,
              maxHeight: constraints.maxHeight + tileHeight,
              child: Wrap(
                spacing: 18,
                runSpacing: 16,
                children: [
                  for (var index = 0; index < columns * rows; index++)
                    SizedBox(
                      width: tileWidth,
                      height: tileHeight,
                      child: Transform.rotate(
                        angle: -0.08,
                        child: Center(
                          child: Text(
                            'NEW\nOFFER',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: const Color(0x38FFD447),
                              fontSize: tileWidth * 0.30,
                              fontWeight: FontWeight.w900,
                              height: 0.72,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrushPanelPainter extends CustomPainter {
  const _BrushPanelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFB4201F);
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.13)
      ..lineTo(size.width * 0.24, size.height * 0.03)
      ..lineTo(size.width * 0.62, size.height * 0.06)
      ..lineTo(size.width * 0.96, size.height * 0.02)
      ..lineTo(size.width * 0.92, size.height * 0.52)
      ..lineTo(size.width, size.height * 0.88)
      ..lineTo(size.width * 0.60, size.height * 0.94)
      ..lineTo(size.width * 0.31, size.height)
      ..lineTo(size.width * 0.03, size.height * 0.86)
      ..lineTo(size.width * 0.08, size.height * 0.54)
      ..close();
    canvas.drawPath(path, paint);

    final darkPaint = Paint()..color = const Color(0x55221B3D);
    for (var i = 0; i < 9; i++) {
      final y = size.height * (0.10 + i * 0.10);
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.04, y, size.width * 0.92, 5),
        darkPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedGridPainter extends CustomPainter {
  const _DottedGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF181A21);
    const spacing = 26.0;
    const radius = 1.4;

    for (var y = 0.0; y <= size.height; y += spacing) {
      for (var x = 0.0; x <= size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OfferItemGrid extends StatelessWidget {
  final List<ComboOfferItem> items;
  final String offerType;
  final bool showPrice;
  final bool showProductImage;
  final double priceFontScale;
  final TvMenuThemeData theme;

  const _OfferItemGrid({
    required this.items,
    required this.offerType,
    required this.showPrice,
    required this.showProductImage,
    required this.priceFontScale,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = items.length;
        final minTileWidth = constraints.maxWidth < 900 ? 170.0 : 230.0;
        final minTileHeight = constraints.maxHeight < 420 ? 190.0 : 245.0;
        var columns = (constraints.maxWidth / minTileWidth).floor();
        columns = columns.clamp(1, count);
        var rows = (count / columns).ceil();
        while (
            rows * minTileHeight > constraints.maxHeight && columns < count) {
          columns++;
          rows = (count / columns).ceil();
        }
        final tileWidth = constraints.maxWidth / columns;
        final tileHeight = constraints.maxHeight / rows;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 22,
            childAspectRatio: tileWidth / tileHeight,
          ),
          itemCount: count,
          itemBuilder: (context, index) {
            return _OfferProductCard(
              item: items[index],
              offerType: offerType,
              showPrice: showPrice,
              showProductImage: showProductImage,
              priceFontScale: priceFontScale,
              theme: theme,
            );
          },
        );
      },
    );
  }
}

class _OfferProductCard extends StatelessWidget {
  final ComboOfferItem item;
  final String offerType;
  final bool showPrice;
  final bool showProductImage;
  final double priceFontScale;
  final TvMenuThemeData theme;

  const _OfferProductCard({
    required this.item,
    required this.offerType,
    required this.showPrice,
    required this.showProductImage,
    required this.priceFontScale,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final menuPrice = item.variantPrice ?? product.price;
    final offerPrice = item.discountPrice ?? menuPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: showProductImage && product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : const Icon(
                      Icons.local_offer_rounded,
                      color: Color(0xFFE32121),
                      size: 72,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          if (item.variantLabel?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              item.variantLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFB9BBC6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (showPrice) ...[
            const SizedBox(height: 8),
            offerType == 'free'
                ? Text(
                    _freeOfferDetail(
                      item,
                      item.buyQuantity ?? item.quantity,
                      item.freeQuantity ?? 1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF6BFFB1),
                      fontSize: 18 * priceFontScale,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (offerPrice < menuPrice) ...[
                        Text(
                          'Rs. ${menuPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF8B8E99),
                            fontSize: 17 * priceFontScale,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: const Color(0xFF8B8E99),
                            decorationThickness: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        'Rs. ${offerPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFFFFD13F),
                          fontSize: 28 * priceFontScale,
                          fontWeight: FontWeight.w900,
                          height: 0.96,
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}

class _BusinessLogo extends StatelessWidget {
  final String? logoUrl;
  final String? businessName;
  final double size;

  const _BusinessLogo({
    required this.logoUrl,
    required this.businessName,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl?.isNotEmpty == true) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final initial = (businessName?.trim().isNotEmpty == true)
        ? businessName!.trim().substring(0, 1).toUpperCase()
        : 'T';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE32121),
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
        ),
      ),
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

String _freeOfferDetail(ComboOfferItem item, int buyQty, int freeQty) {
  return 'Buy $buyQty ${_productLabel(item)}, get $freeQty ${_freeProductLabel(item)} free';
}

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _offerLocalized(String language, String key) {
  if (_isMalayalam(language)) {
    return switch (key) {
      'discountOffer' => 'ഡിസ്കൗണ്ട് ഓഫർ',
      _ => key,
    };
  }
  return switch (key) {
    'discountOffer' => 'Discount Offer',
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
