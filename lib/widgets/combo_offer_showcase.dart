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
    final end = (start + perPage).clamp(0, combos.length);
    final pageCombos = combos.sublist(start, end);
    final availableHeight =
        (screenSize.height - 128).clamp(360.0, screenSize.height);
    final offerHeight = availableHeight / pageCombos.length;

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
      child: Padding(
        key: ValueKey('combo-$safePage'),
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'COMBO OFFER',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: ((screenSize.width * 0.034) * headingFontScale)
                    .clamp(30.0, 68.0),
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: catTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < pageCombos.length; i++)
              SizedBox(
                height: offerHeight,
                child: _ComboOfferFeature(
                  combo: pageCombos[i],
                  catTheme: catTheme,
                  theme: theme,
                  screenWidth: screenSize.width,
                  offerHeight: offerHeight,
                  nameFontScale: nameFontScale,
                  priceFontScale: priceFontScale,
                  showPrice: showPrice,
                  showProductImage: showProductImage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComboOfferFeature extends StatelessWidget {
  final MenuItem combo;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final double screenWidth;
  final double offerHeight;
  final double nameFontScale;
  final double priceFontScale;
  final bool showPrice;
  final bool showProductImage;

  const _ComboOfferFeature({
    required this.combo,
    required this.catTheme,
    required this.theme,
    required this.screenWidth,
    required this.offerHeight,
    required this.nameFontScale,
    required this.priceFontScale,
    required this.showPrice,
    required this.showProductImage,
  });

  @override
  Widget build(BuildContext context) {
    final original = combo.originalPrice ?? _comboOriginalPrice(combo);
    final discount = original > 0 && combo.price > 0
        ? (((original - combo.price) / original) * 100).clamp(0, 99).round()
        : 0;
    final nameFontSize =
        ((screenWidth * 0.050) * nameFontScale).clamp(42.0, 96.0);
    final priceFontSize =
        ((screenWidth * 0.054) * priceFontScale).clamp(48.0, 104.0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.08,
        vertical: offerHeight * 0.05,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            combo.name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.playfairDisplay(
              color: theme.primaryText,
              fontSize: nameFontSize,
              height: 0.96,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: offerHeight * 0.018),
          if (showPrice)
            Text(
              'Rs. ${combo.price.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: catTheme.accent,
                fontSize: priceFontSize,
                height: 0.92,
                fontWeight: FontWeight.w900,
              ),
            ),
          SizedBox(height: offerHeight * 0.014),
          _OriginalPriceLine(
            original: original,
            discount: discount,
            theme: theme,
            fontSize: (screenWidth * 0.020).clamp(22.0, 38.0),
          ),
          SizedBox(height: offerHeight * 0.050),
          Expanded(
            child: Center(
              child: _ComboProductGrid(
                items: combo.comboItems,
                maxWidth: screenWidth * 0.80,
                catTheme: catTheme,
                theme: theme,
                showProductImage: showProductImage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboProductGrid extends StatelessWidget {
  final List<ComboOfferItem> items;
  final double maxWidth;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool showProductImage;

  const _ComboProductGrid({
    required this.items,
    required this.maxWidth,
    required this.catTheme,
    required this.theme,
    required this.showProductImage,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = items.length <= 4
              ? items.length
              : items.length <= 8
                  ? 4
                  : 5;
          final spacing = (constraints.maxWidth * 0.026).clamp(22.0, 42.0);
          final tileWidth =
              ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                  .clamp(142.0, 240.0);
          final imageSize = (tileWidth * 0.74).clamp(104.0, 164.0);

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing * 0.70,
              children: [
                for (final item in items)
                  SizedBox(
                    width: tileWidth,
                    child: _ComboProductTile(
                      item: item,
                      imageSize: imageSize,
                      catTheme: catTheme,
                      theme: theme,
                      showProductImage: showProductImage,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComboProductTile extends StatelessWidget {
  final ComboOfferItem item;
  final double imageSize;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool showProductImage;

  const _ComboProductTile({
    required this.item,
    required this.imageSize,
    required this.catTheme,
    required this.theme,
    required this.showProductImage,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _absoluteImageUrl(item.product.imageUrl);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.86),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: catTheme.primary.withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: !showProductImage || imageUrl == null
              ? _ImageFallback(catTheme: catTheme, theme: theme)
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _ImageFallback(catTheme: catTheme, theme: theme),
                  errorWidget: (_, __, ___) =>
                      _ImageFallback(catTheme: catTheme, theme: theme),
                ),
        ),
        const SizedBox(height: 10),
        _ComboDetailLine(item: item, catTheme: catTheme, theme: theme),
      ],
    );
  }
}

class _OriginalPriceLine extends StatelessWidget {
  final double original;
  final int discount;
  final TvMenuThemeData theme;
  final double fontSize;

  const _OriginalPriceLine({
    required this.original,
    required this.discount,
    required this.theme,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (original <= 0 || discount <= 0) return const SizedBox.shrink();
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.nunito(
          color: theme.secondaryText.withValues(alpha: 0.74),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
        children: [
          TextSpan(
            text: 'Rs. ${original.toStringAsFixed(0)}',
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          TextSpan(text: ' ($discount% off)'),
        ],
      ),
    );
  }
}

class _ComboDetailLine extends StatelessWidget {
  final ComboOfferItem item;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;

  const _ComboDetailLine({
    required this.item,
    required this.catTheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final detail = _comboItemDetail(item);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.nunito(
            color: theme.primaryText,
            fontSize: 19,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
          children: [
            TextSpan(text: item.product.name),
            const TextSpan(text: '\n'),
            TextSpan(
              text: detail,
              style: GoogleFonts.nunito(
                color: catTheme.accent,
                fontSize: 19,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;

  const _ImageFallback({required this.catTheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: catTheme.primary.withValues(alpha: theme.isDark ? 0.28 : 0.18),
      child: Center(
        child: Text(
          'COMBO',
          style: GoogleFonts.nunito(
            color: theme.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

double _comboOriginalPrice(MenuItem combo) {
  return combo.comboItems.fold<double>(
    0,
    (total, item) =>
        total + (item.variantPrice ?? item.product.price) * item.quantity,
  );
}

String _comboItemDetail(ComboOfferItem item) {
  final selectedLabel = item.variantLabel?.trim();
  if (selectedLabel != null && selectedLabel.isNotEmpty) return selectedLabel;

  if (item.variantPrice != null) {
    for (final variant in item.product.priceVariants) {
      if ((variant.price - item.variantPrice!).abs() < 0.01 &&
          variant.label.trim().isNotEmpty) {
        return variant.label.trim();
      }
    }
  }

  if (item.product.priceVariants.isNotEmpty) {
    final fullVariant = item.product.priceVariants
        .where((variant) => variant.label.trim().toLowerCase() == 'full')
        .cast<PriceVariant?>()
        .firstWhere((variant) => variant != null, orElse: () => null);
    if (fullVariant != null) return fullVariant.label.trim();
    final fallback = item.product.priceVariants.last.label.trim();
    if (fallback.isNotEmpty) return fallback;
  }

  return item.quantity.toString();
}

String? _absoluteImageUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http')) return value;
  final path = value.startsWith('/') ? value.substring(1) : value;
  return 'http://192.168.29.184:4002/$path';
}
