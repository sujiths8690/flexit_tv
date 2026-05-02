// lib/widgets/menu_header_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class MenuHeaderWidget extends StatelessWidget {
  final String? businessName;
  final MenuCategory category;
  final CategoryTheme catTheme;
  final double fontScale;
  final int itemCount;

  const MenuHeaderWidget({
    super.key,
    required this.businessName,
    required this.category,
    required this.catTheme,
    required this.fontScale,
    required this.itemCount,
  });

  String get _categoryLabel {
    switch (category) {
      case MenuCategory.veg:        return 'Pure Vegetarian';
      case MenuCategory.nonVeg:     return 'Non Vegetarian';
      case MenuCategory.todaysStar: return "Today's Stars";
      case MenuCategory.beverages:  return 'Beverages';
      case MenuCategory.desserts:   return 'Desserts';
      case MenuCategory.all:        return 'Full Menu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: catTheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Category icon + label
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: catTheme.primary.withOpacity(0.15),
              border: Border.all(
                color: catTheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              catTheme.icon,
              style: TextStyle(fontSize: 22 * fontScale),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: GoogleFonts.nunito().fontFamily,
                    fontSize: 11 * fontScale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: catTheme.accent,
                  ),
                ),
                if (businessName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    businessName!,
                    style: TextStyle(
                      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                      fontSize: 22 * fontScale,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Live badge + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LiveBadge(),
              const SizedBox(height: 4),
              _ClockWidget(color: AppTheme.whiteDim),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.vegGreen.withOpacity(_opacity.value),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.vegGreen.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              fontFamily: GoogleFonts.nunito().fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppTheme.vegGreen.withOpacity(_opacity.value),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  final Color color;
  const _ClockWidget({required this.color});

  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _update();
    // Refresh every second
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) _update();
    });
  }

  void _update() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour < 12 ? 'AM' : 'PM';
    setState(() => _time = '$h:$m $ampm');
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: TextStyle(
        fontFamily: GoogleFonts.nunito().fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: widget.color,
      ),
    );
  }
}
