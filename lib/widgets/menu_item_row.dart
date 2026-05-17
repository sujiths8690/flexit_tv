// lib/widgets/menu_item_row.dart
//
// Full-width alternating menu row with a large circular food image.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MenuItemRow extends StatefulWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool imageOnLeft;
  final Duration animationDelay;
  final double screenWidth;
  final double rowHeight;
  final bool showPrice;
  final bool showDescription;
  final bool showProductImage;
  final bool showDietTags;
  final double nameFontScale;
  final double descriptionFontScale;
  final double priceFontScale;

  const MenuItemRow({
    super.key,
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.animationDelay,
    required this.screenWidth,
    required this.rowHeight,
    this.showPrice = true,
    this.showDescription = true,
    this.showProductImage = true,
    this.showDietTags = true,
    this.nameFontScale = 1.0,
    this.descriptionFontScale = 1.0,
    this.priceFontScale = 1.0,
  });

  @override
  State<MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<MenuItemRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(widget.imageOnLeft ? -0.06 : 0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _RowContent(
          item: widget.item,
          catTheme: widget.catTheme,
          theme: widget.theme,
          imageOnLeft: widget.imageOnLeft,
          screenWidth: widget.screenWidth,
          rowHeight: widget.rowHeight,
          showPrice: widget.showPrice,
          showDescription: widget.showDescription,
          showProductImage: widget.showProductImage,
          showDietTags: widget.showDietTags,
          nameFontScale: widget.nameFontScale,
          descriptionFontScale: widget.descriptionFontScale,
          priceFontScale: widget.priceFontScale,
        ),
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool imageOnLeft;
  final double screenWidth;
  final double rowHeight;
  final bool showPrice;
  final bool showDescription;
  final bool showProductImage;
  final bool showDietTags;
  final double nameFontScale;
  final double descriptionFontScale;
  final double priceFontScale;

  const _RowContent({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.screenWidth,
    required this.rowHeight,
    required this.showPrice,
    required this.showDescription,
    required this.showProductImage,
    required this.showDietTags,
    required this.nameFontScale,
    required this.descriptionFontScale,
    required this.priceFontScale,
  });

  double get imageSize =>
      min(rowHeight * 0.82, (screenWidth * 0.34).clamp(170.0, 430.0));
  double get hPad => screenWidth * 0.04;

  @override
  Widget build(BuildContext context) {
    final textBlock = _TextBlock(
      item: item,
      catTheme: catTheme,
      theme: theme,
      imageOnLeft: imageOnLeft,
      screenWidth: screenWidth,
      rowHeight: rowHeight,
      showPrice: showPrice,
      showDescription: showDescription,
      showDietTags: showDietTags,
      nameFontScale: nameFontScale,
      descriptionFontScale: descriptionFontScale,
      priceFontScale: priceFontScale,
    );
    final imageBlock = showProductImage
        ? Flexible(
            flex: 0,
            child: _ImageCircle(
              item: item,
              catTheme: catTheme,
              size: imageSize,
              imageOnLeft: imageOnLeft,
            ),
          )
        : const SizedBox.shrink();

    final row = SizedBox(
      height: rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: imageOnLeft
              ? [
                  if (showProductImage) imageBlock,
                  Expanded(child: textBlock),
                ]
              : [
                  Expanded(child: textBlock),
                  if (showProductImage) imageBlock,
                ],
        ),
      ),
    );

    return _UnavailableTreatment(
      enabled: !item.isAvailable,
      child: row,
    );
  }
}

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

class _ImageCircle extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final double size;
  final bool imageOnLeft;

  const _ImageCircle({
    required this.item,
    required this.catTheme,
    required this.size,
    required this.imageOnLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        right: imageOnLeft ? 24 : 0,
        left: imageOnLeft ? 0 : 24,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipOval(
          child: item.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      _PlaceholderCircle(catTheme: catTheme),
                  errorWidget: (_, __, ___) =>
                      _PlaceholderCircle(catTheme: catTheme),
                )
              : _PlaceholderCircle(catTheme: catTheme),
        ),
      ),
    );
  }
}

class _PlaceholderCircle extends StatelessWidget {
  final CategoryTheme catTheme;
  const _PlaceholderCircle({required this.catTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            catTheme.gradient[0].withOpacity(0.75),
            catTheme.gradient[1].withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          catTheme.icon,
          style: GoogleFonts.nunito(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool imageOnLeft;
  final double screenWidth;
  final double rowHeight;
  final bool showPrice;
  final bool showDescription;
  final bool showDietTags;
  final double nameFontScale;
  final double descriptionFontScale;
  final double priceFontScale;

  const _TextBlock({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.screenWidth,
    required this.rowHeight,
    required this.showPrice,
    required this.showDescription,
    required this.showDietTags,
    required this.nameFontScale,
    required this.descriptionFontScale,
    required this.priceFontScale,
  });

  double get _rowScale => (rowHeight / 190).clamp(0.78, 1.0);
  double get nameFontSize =>
      ((screenWidth * 0.022).clamp(18.0, 32.0) * _rowScale * nameFontScale)
          .clamp(14.0, 36.0);
  double get priceFontSize =>
      ((screenWidth * 0.026).clamp(22.0, 38.0) * _rowScale * priceFontScale)
          .clamp(17.0, 42.0);
  double get descFontSize => ((screenWidth * 0.013).clamp(11.0, 18.0) *
          _rowScale *
          descriptionFontScale)
      .clamp(9.0, 20.0);
  double get verticalPad => (rowHeight * 0.08).clamp(8.0, 16.0);
  double get titleGap => (rowHeight * 0.04).clamp(4.0, 8.0);
  double get metaGap => (rowHeight * 0.045).clamp(5.0, 9.0);

  @override
  Widget build(BuildContext context) {
    final alignment =
        imageOnLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = imageOnLeft ? TextAlign.left : TextAlign.right;
    final hasPriceVariants = item.priceVariants.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: imageOnLeft ? 0 : 16,
        right: imageOnLeft ? 16 : 0,
        top: verticalPad,
        bottom: verticalPad,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                imageOnLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: alignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  hasPriceVariants
                      ? Column(
                          crossAxisAlignment: alignment,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NameText(
                              item: item,
                              theme: theme,
                              fontSize: nameFontSize,
                              flexible: false,
                            ),
                            SizedBox(height: titleGap),
                            if (showPrice)
                              _PriceText(
                                item: item,
                                catTheme: catTheme,
                                fontSize: priceFontSize,
                              ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: imageOnLeft
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: imageOnLeft
                              ? [
                                  _NameText(
                                    item: item,
                                    theme: theme,
                                    fontSize: nameFontSize,
                                  ),
                                  if (showPrice) ...[
                                    const SizedBox(width: 16),
                                    _PriceText(
                                      item: item,
                                      catTheme: catTheme,
                                      fontSize: priceFontSize,
                                    ),
                                  ],
                                ]
                              : [
                                  if (showPrice) ...[
                                    _PriceText(
                                      item: item,
                                      catTheme: catTheme,
                                      fontSize: priceFontSize,
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  _NameText(
                                    item: item,
                                    theme: theme,
                                    fontSize: nameFontSize,
                                  ),
                                ],
                        ),
                  SizedBox(height: titleGap),
                  if (showDescription && item.description != null)
                    Text(
                      item.description!,
                      style: GoogleFonts.nunito(
                        fontSize: descFontSize,
                        color: theme.secondaryText,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: rowHeight < 155 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: textAlign,
                    ),
                  SizedBox(height: metaGap),
                  _MetaRow(
                    item: item,
                    catTheme: catTheme,
                    theme: theme,
                    imageOnLeft: imageOnLeft,
                    fontSize: descFontSize,
                    showDietTags: showDietTags,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final bool imageOnLeft;
  final double fontSize;
  final bool showDietTags;

  const _MetaRow({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.fontSize,
    required this.showDietTags,
  });

  @override
  Widget build(BuildContext context) {
    final dietTag = item.tags.contains('nonVeg')
        ? 'nonVeg'
        : item.tags.contains('veg')
            ? 'veg'
            : null;
    final originalPrice = item.originalPrice == null
        ? null
        : Text(
            'Rs. ${item.originalPrice!.toStringAsFixed(0)}',
            style: GoogleFonts.nunito(
              fontSize: fontSize * 0.92,
              color: theme.secondaryText.withOpacity(0.6),
              decoration: TextDecoration.lineThrough,
              decorationColor: theme.secondaryText.withOpacity(0.5),
            ),
          );

    final children = [
      if (showDietTags && dietTag != null)
        _DietSymbol(tag: dietTag, size: (fontSize * 1.35).clamp(14.0, 24.0)),
      if (originalPrice != null) originalPrice,
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: imageOnLeft ? WrapAlignment.start : WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: children,
    );
  }
}

class _NameText extends StatelessWidget {
  final MenuItem item;
  final TvMenuThemeData theme;
  final double fontSize;
  final bool flexible;

  const _NameText({
    required this.item,
    required this.theme,
    required this.fontSize,
    this.flexible = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      item.name,
      style: GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: theme.primaryText,
        height: 1.15,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return flexible ? Flexible(child: text) : text;
  }
}

class _PriceText extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final double fontSize;

  const _PriceText({
    required this.item,
    required this.catTheme,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final text = item.priceVariants.isNotEmpty
        ? item.priceVariants
            .map((variant) =>
                '${variant.label} Rs. ${variant.price.toStringAsFixed(0)}')
            .join('  ')
        : 'Rs. ${item.price.toStringAsFixed(0)}';
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: item.priceVariants.isNotEmpty ? fontSize * 0.72 : fontSize,
        fontWeight: FontWeight.w700,
        color: catTheme.accent,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DietSymbol extends StatelessWidget {
  final String tag;
  final double size;

  const _DietSymbol({required this.tag, required this.size});

  @override
  Widget build(BuildContext context) {
    final isVeg = tag == 'veg';
    final color = isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: max(1.4, size * 0.08)),
        borderRadius: BorderRadius.circular(size * 0.12),
      ),
      child: Center(
        child: isVeg
            ? Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            : CustomPaint(
                size: Size.square(size * 0.48),
                painter: _NonVegTrianglePainter(color),
              ),
      ),
    );
  }
}

class _NonVegTrianglePainter extends CustomPainter {
  final Color color;

  const _NonVegTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NonVegTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
