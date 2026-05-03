// lib/widgets/menu_item_row.dart
//
// Full-width alternating menu row with a large circular food image.

import 'package:flutter/material.dart';
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

  const MenuItemRow({
    super.key,
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.animationDelay,
    required this.screenWidth,
    required this.rowHeight,
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

  const _RowContent({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.screenWidth,
    required this.rowHeight,
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
    );
    final imageBlock = Flexible(
      flex: 0,
      child: _ImageCircle(
      item: item,
      catTheme: catTheme,
      size: imageSize,
      imageOnLeft: imageOnLeft,
      ),
    );

    return SizedBox(
      height: rowHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: imageOnLeft
              ? [imageBlock, Expanded(child: textBlock)]
              : [Expanded(child: textBlock), imageBlock],
        ),
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
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _PlaceholderCircle(catTheme: catTheme),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : _PlaceholderCircle(catTheme: catTheme),
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

  const _TextBlock({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.screenWidth,
    required this.rowHeight,
  });

  double get _rowScale => (rowHeight / 190).clamp(0.78, 1.0);
  double get nameFontSize =>
      ((screenWidth * 0.022).clamp(18.0, 32.0) * _rowScale).clamp(16.0, 32.0);
  double get priceFontSize =>
      ((screenWidth * 0.026).clamp(22.0, 38.0) * _rowScale).clamp(19.0, 38.0);
  double get descFontSize =>
      ((screenWidth * 0.013).clamp(11.0, 18.0) * _rowScale).clamp(10.0, 18.0);
  double get verticalPad => (rowHeight * 0.08).clamp(8.0, 16.0);
  double get titleGap => (rowHeight * 0.04).clamp(4.0, 8.0);
  double get metaGap => (rowHeight * 0.045).clamp(5.0, 9.0);

  @override
  Widget build(BuildContext context) {
    final alignment =
        imageOnLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final textAlign = imageOnLeft ? TextAlign.left : TextAlign.right;

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
                  Row(
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
                            const SizedBox(width: 16),
                            _PriceText(
                              item: item,
                              catTheme: catTheme,
                              fontSize: priceFontSize,
                            ),
                          ]
                        : [
                            _PriceText(
                              item: item,
                              catTheme: catTheme,
                              fontSize: priceFontSize,
                            ),
                            const SizedBox(width: 16),
                            _NameText(
                              item: item,
                              theme: theme,
                              fontSize: nameFontSize,
                            ),
                          ],
                  ),
                  SizedBox(height: titleGap),
                  if (item.description != null)
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

  const _MetaRow({
    required this.item,
    required this.catTheme,
    required this.theme,
    required this.imageOnLeft,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final tags = item.tags
        .take(2)
        .map((tag) => _TagChip(tag: tag, catTheme: catTheme))
        .toList();
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
      ...tags,
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

  const _NameText({
    required this.item,
    required this.theme,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        item.name,
        style: GoogleFonts.playfairDisplay(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: theme.primaryText,
          height: 1.15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
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
    return Text(
      'Rs. ${item.price.toStringAsFixed(0)}',
      style: GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: catTheme.accent,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final CategoryTheme catTheme;

  const _TagChip({required this.tag, required this.catTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: catTheme.primary.withOpacity(0.1),
        border: Border.all(
          color: catTheme.primary.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        tag,
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: catTheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
