// lib/screens/menu_board_screen.dart
//
// Renders the premium menu board. Adapts to screen size and orientation.
// Auto-scrolls through items if there are many.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/orientation_helper.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/menu_header_widget.dart';
import '../widgets/ticker_bar_widget.dart';

class MenuBoardScreen extends StatefulWidget {
  final DeviceConfig config;
  final DisplayConfig displayConfig;
  final Size screenSize;

  const MenuBoardScreen({
    super.key,
    required this.config,
    required this.displayConfig,
    required this.screenSize,
  });

  @override
  State<MenuBoardScreen> createState() => _MenuBoardScreenState();
}

class _MenuBoardScreenState extends State<MenuBoardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late ScrollController _scrollCtrl;
  Timer? _autoScrollTimer;
  List<MenuItem> _items = [];
  MenuCategory get _category =>
      widget.displayConfig.menuCategory ?? MenuCategory.all;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scrollCtrl = ScrollController();

    _loadItems();
    _startAutoScroll();
  }

  void _loadItems() {
    // In production: fetch from your API
    final all = MockData.sampleMenuItems;
    setState(() {
      _items = _category == MenuCategory.all
          ? all
          : all.where((i) => i.category == _category).toList();
    });
  }

  void _startAutoScroll() {
    final interval = widget.displayConfig.autoScrollIntervalSeconds ?? 8;
    _autoScrollTimer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!_scrollCtrl.hasClients) return;
      final maxScroll = _scrollCtrl.position.maxScrollExtent;
      final current = _scrollCtrl.offset;
      final step = widget.screenSize.height * 0.8;
      if (current + step >= maxScroll) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut);
      } else {
        _scrollCtrl.animateTo(current + step,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  CategoryTheme get _catTheme {
    final key = _category.name == 'nonVeg'
        ? 'non_veg'
        : _category.name == 'todaysStar'
            ? 'todays_star'
            : _category.name;
    return AppTheme.categoryThemes[key] ??
        AppTheme.categoryThemes['veg']!;
  }

  @override
  Widget build(BuildContext context) {
    final cols = OrientationHelper.gridColumns(widget.screenSize.width);
    final fScale = OrientationHelper.fontScale(widget.screenSize.width);
    final catTheme = _catTheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            // ── Gradient background ────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      catTheme.gradient[0],
                      AppTheme.background,
                      catTheme.gradient[1].withOpacity(0.3),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // ── Content ────────────────────────────────────────────────
            Column(
              children: [
                // Header
                MenuHeaderWidget(
                  businessName: widget.config.businessName,
                  category: _category,
                  catTheme: catTheme,
                  fontScale: fScale,
                  itemCount: _items.length,
                ),

                // Menu grid
                Expanded(
                  child: _items.isEmpty
                      ? _EmptyState(catTheme: catTheme)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: GridView.builder(
                            controller: _scrollCtrl,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: cols >= 3 ? 0.78 : 0.82,
                            ),
                            itemCount: _items.length,
                            itemBuilder: (ctx, i) => MenuItemCard(
                              item: _items[i],
                              catTheme: catTheme,
                              fontScale: fScale,
                              animationDelay: Duration(milliseconds: i * 80),
                            ),
                          ),
                        ),
                ),

                // Ticker / promo bar
                TickerBarWidget(catTheme: catTheme),

                // Mascot space
                const SizedBox(height: 100),
              ],
            ),

            // ── Mascot ─────────────────────────────────────────────────
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MascotWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final CategoryTheme catTheme;
  const _EmptyState({required this.catTheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(catTheme.icon, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No items available',
            style: TextStyle(
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              fontSize: 24,
              color: AppTheme.whiteDim,
            ),
          ),
        ],
      ),
    );
  }
}
