// lib/widgets/menu_item_card.dart
//
// Each menu category gets its own visual treatment:
//   Veg       → green accents, leaf motif
//   Non-Veg   → red accents, flame motif
//   Star      → amber gradient, star badge
//   Beverages → blue tones, bubble motif
//   Desserts  → pink tones, sparkle motif

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MenuItemCard extends StatefulWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final double fontScale;
  final Duration animationDelay;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.catTheme,
    required this.fontScale,
    required this.animationDelay,
  });

  @override
  State<MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<MenuItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

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
        child: _UnavailableTreatment(
          enabled: !widget.item.isAvailable,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: _CardContent(
              item: widget.item,
              catTheme: widget.catTheme,
              fontScale: widget.fontScale,
            ),
          ),
        ),
      ),
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

class _CardContent extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final double fontScale;

  const _CardContent({
    required this.item,
    required this.catTheme,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final hasPriceVariants = item.priceVariants.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceElevated,
            AppTheme.surface,
          ],
        ),
        border: Border.all(
          color: item.isFeatured
              ? catTheme.primary.withOpacity(0.5)
              : AppTheme.cardBorder,
          width: item.isFeatured ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isFeatured
                ? catTheme.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.25),
            blurRadius: item.isFeatured ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Image area ─────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  item.imageUrl != null
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _PlaceholderImage(catTheme: catTheme),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return _PlaceholderImage(catTheme: catTheme);
                          },
                        )
                      : _PlaceholderImage(catTheme: catTheme),

                  // Gradient overlay from bottom
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.surface.withOpacity(0.8),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Featured star badge
                  if (item.isFeatured)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: catTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: catTheme.primary.withOpacity(0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '★ STAR',
                          style: TextStyle(
                            fontFamily: GoogleFonts.nunito().fontFamily,
                            fontSize: 9 * fontScale,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.background,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                  // Diet indicator dot (top-left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _DietIndicator(category: item.category),
                  ),
                ],
              ),
            ),

            // ── Info area ──────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name
                    Text(
                      item.name,
                      style: TextStyle(
                        fontFamily: GoogleFonts.nunito().fontFamily,
                        fontSize: 14 * fontScale,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.white,
                        height: 1.2,
                      ),
                      maxLines: hasPriceVariants ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Description
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontFamily: GoogleFonts.nunito().fontFamily,
                          fontSize: 10 * fontScale,
                          color: AppTheme.whiteDim,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Price row
                    hasPriceVariants
                        ? _VariantPriceText(
                            item: item,
                            catTheme: catTheme,
                            fontScale: fontScale,
                          )
                        : Row(
                            children: [
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontFamily: GoogleFonts.nunito().fontFamily,
                                  fontSize: 18 * fontScale,
                                  fontWeight: FontWeight.w900,
                                  color: catTheme.accent,
                                ),
                              ),
                              if (item.originalPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '₹${item.originalPrice!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontFamily: GoogleFonts.nunito().fontFamily,
                                    fontSize: 11 * fontScale,
                                    color: AppTheme.whiteDim,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Tags
                              if (item.tags.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: catTheme.primary.withOpacity(0.15),
                                  ),
                                  child: Text(
                                    item.tags.first,
                                    style: TextStyle(
                                      fontFamily:
                                          GoogleFonts.nunito().fontFamily,
                                      fontSize: 9 * fontScale,
                                      color: catTheme.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
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

class _VariantPriceText extends StatelessWidget {
  final MenuItem item;
  final CategoryTheme catTheme;
  final double fontScale;

  const _VariantPriceText({
    required this.item,
    required this.catTheme,
    required this.fontScale,
  });

  @override
  Widget build(BuildContext context) {
    final text = item.priceVariants
        .map((variant) =>
            '${variant.label} Rs. ${variant.price.toStringAsFixed(0)}')
        .join('  ');

    return Text(
      text,
      style: TextStyle(
        fontFamily: GoogleFonts.nunito().fontFamily,
        fontSize: 12 * fontScale,
        fontWeight: FontWeight.w900,
        color: catTheme.accent,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DietIndicator extends StatelessWidget {
  final MenuCategory category;
  const _DietIndicator({required this.category});

  @override
  Widget build(BuildContext context) {
    final isVeg = category == MenuCategory.veg ||
        category == MenuCategory.beverages ||
        category == MenuCategory.desserts;
    final color = isVeg ? AppTheme.vegGreen : AppTheme.nonVegRed;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final CategoryTheme catTheme;
  const _PlaceholderImage({required this.catTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: catTheme.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          catTheme.icon,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}
