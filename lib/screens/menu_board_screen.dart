// lib/screens/menu_board_screen.dart
//
// TV menu board with an editorial alternating row layout.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_item_row.dart';

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
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _bgCtrl;
  Timer? _pageTimer;
  List<MenuItem> _items = [];
  List<List<MenuItem>> _categoryGroups = [];
  int _groupIndex = 0;
  int _pageIndex = 0;
  String _contentSignature = '';

  MenuCategory get _category =>
      widget.displayConfig.menuCategory ?? MenuCategory.all;

  MenuThemeType get _themeType {
    if (widget.config.menuTheme != null) return widget.config.menuTheme!;
    final override = widget.displayConfig.themeOverride;
    if (override == null) return MenuThemeType.light;
    return MenuThemeType.values.firstWhere(
      (theme) => theme.name == override,
      orElse: () => MenuThemeType.light,
    );
  }

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _contentSignature = _buildContentSignature(widget.displayConfig.menuItems);
    _loadItems();
    _startPageTimer();
  }

  @override
  void didUpdateWidget(MenuBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayConfig.menuCategory !=
            widget.displayConfig.menuCategory ||
        oldWidget.displayConfig.themeOverride !=
            widget.displayConfig.themeOverride ||
        _contentSignature !=
            _buildContentSignature(widget.displayConfig.menuItems) ||
        oldWidget.displayConfig.contentMode != widget.displayConfig.contentMode ||
        oldWidget.config.menuTheme != widget.config.menuTheme) {
      _contentSignature = _buildContentSignature(widget.displayConfig.menuItems);
      _fadeCtrl.reset();
      _loadItems();
      _fadeCtrl.forward();
    }

    if (oldWidget.displayConfig.autoScrollIntervalSeconds !=
        widget.displayConfig.autoScrollIntervalSeconds) {
      _startPageTimer();
    }
  }

  String _buildContentSignature(List<MenuItem> items) {
    return items
        .map(
          (item) =>
              '${item.id}:${item.name}:${item.price}:${item.imageUrl ?? ''}:${item.categoryId ?? ''}',
        )
        .join('|');
  }

  void _loadItems() {
    final all = widget.displayConfig.menuItems;
    setState(() {
      _pageIndex = 0;
      _groupIndex = 0;
      _categoryGroups = _buildCategoryGroups(all);
      _items = _categoryGroups.isNotEmpty ? _categoryGroups.first : all;
    });
  }

  List<List<MenuItem>> _buildCategoryGroups(List<MenuItem> all) {
    if (widget.displayConfig.contentMode != 'allCategories') {
      return [
        _category == MenuCategory.all
            ? all
            : all.where((i) => i.category == _category).toList()
      ];
    }
    final groups = <String, List<MenuItem>>{};
    for (final item in all) {
      final key = item.categoryId?.toString() ?? item.categoryName ?? 'menu';
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups.values.where((items) => items.isNotEmpty).toList();
  }

  int _itemsPerPage(Size size) {
    const verticalPadding = 56.0;
    const dividerHeight = 1.0;
    final baseRowHeight = (size.width * 0.12).clamp(170.0, 220.0);
    final availableHeight =
        (size.height - verticalPadding).clamp(180.0, size.height);
    final count = (availableHeight / (baseRowHeight + dividerHeight)).floor();
    return count.clamp(1, 6);
  }

  void _startPageTimer() {
    final interval = widget.displayConfig.autoScrollIntervalSeconds ?? 8;
    _pageTimer?.cancel();
    _pageTimer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!mounted || _items.isEmpty) return;
      final itemsPerPage = _itemsPerPage(widget.screenSize);
      final pageCount = (_items.length / itemsPerPage).ceil();
      final visibleGroupCount =
          _categoryGroups.where((group) => group.isNotEmpty).length;
      if (pageCount <= 1 && visibleGroupCount <= 1) return;
      setState(() {
        if (_pageIndex + 1 < pageCount) {
          _pageIndex++;
          return;
        }
        _pageIndex = 0;
        if (_categoryGroups.length > 1) {
          _groupIndex = (_groupIndex + 1) % _categoryGroups.length;
          _items = _categoryGroups[_groupIndex];
        }
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bgCtrl.dispose();
    _pageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.menuTheme(_themeType);
    final baseCatTheme = AppTheme.categoryThemes[_category.name] ??
        AppTheme.categoryThemes['all']!;
    final catTheme = AppTheme.colorizedCategoryTheme(
      baseCatTheme,
      widget.config.themeColor.isNotEmpty
          ? widget.config.themeColor
          : widget.displayConfig.themeColor,
    );

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: _AnimatedMenuBackground(
                controller: _bgCtrl,
                theme: theme,
                catTheme: catTheme,
              ),
            ),
            Positioned.fill(
              child: _items.isEmpty
                  ? _EmptyState(catTheme: catTheme, theme: theme)
                  : _PagedMenu(
                      items: _items,
                      pageIndex: _pageIndex,
                      groupIndex: _groupIndex,
                      catTheme: catTheme,
                      theme: theme,
                      screenSize: widget.screenSize,
                      transitionStyle: widget.displayConfig.transitionStyle,
                      transitionSpeedSeconds:
                          widget.displayConfig.transitionSpeedSeconds,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PagedMenu extends StatelessWidget {
  final List<MenuItem> items;
  final int pageIndex;
  final int groupIndex;
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  final Size screenSize;
  final String transitionStyle;
  final double transitionSpeedSeconds;

  const _PagedMenu({
    required this.items,
    required this.pageIndex,
    required this.groupIndex,
    required this.catTheme,
    required this.theme,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
  });

  static const double _verticalPadding = 56;

  int get _itemsPerPage {
    const dividerHeight = 1.0;
    final baseRowHeight = (screenSize.width * 0.12).clamp(170.0, 220.0);
    final availableHeight =
        (screenSize.height - _verticalPadding).clamp(180.0, screenSize.height);
    final count = (availableHeight / (baseRowHeight + dividerHeight)).floor();
    return count.clamp(1, 6);
  }

  double get _baseRowHeight => (screenSize.width * 0.12).clamp(170.0, 220.0);

  @override
  Widget build(BuildContext context) {
    final itemsPerPage = _itemsPerPage;
    final pageCount =
        (items.length / itemsPerPage).ceil().clamp(1, items.length);
    final safePageIndex = pageIndex % pageCount;
    final start = safePageIndex * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, items.length);
    final pageItems = items.sublist(start, end);
    final dividerCount = pageItems.length > 1 ? pageItems.length - 1 : 0;
    final availableHeight =
        (screenSize.height - _verticalPadding).clamp(180.0, screenSize.height);
    final stretchedRowHeight =
        (availableHeight - dividerCount) / pageItems.length;
    final sparseRowHeight =
        (screenSize.height * 0.34).clamp(_baseRowHeight, 380.0);
    final rowHeight = pageItems.length <= 2
        ? min(stretchedRowHeight, sparseRowHeight)
        : stretchedRowHeight;
    final rows = <Widget>[];

    for (var i = 0; i < pageItems.length; i++) {
      final itemIndex = start + i;
      rows.add(
        MenuItemRow(
          item: pageItems[i],
          catTheme: catTheme,
          theme: theme,
          imageOnLeft: itemIndex.isEven,
          animationDelay: Duration(milliseconds: i * 100),
          screenWidth: screenSize.width,
          rowHeight: rowHeight,
        ),
      );

      if (i < pageItems.length - 1) {
        rows.add(_RowDivider(theme: theme));
      }
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: (transitionSpeedSeconds * 1000).round()),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        switch (transitionStyle.toLowerCase()) {
          case 'slide':
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          case 'zoom':
            return ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
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
      child: Padding(
        key: ValueKey('$groupIndex-$safePageIndex'),
        padding: const EdgeInsets.symmetric(vertical: _verticalPadding / 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: rows,
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final TvMenuThemeData theme;
  const _RowDivider({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Divider(
        color: theme.divider,
        height: 1,
        thickness: 0.5,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final CategoryTheme catTheme;
  final TvMenuThemeData theme;
  const _EmptyState({required this.catTheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            catTheme.icon,
            style: GoogleFonts.nunito(
              fontSize: 34,
              color: catTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add items from the app',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New products and media will appear here automatically.',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedMenuBackground extends StatelessWidget {
  final Animation<double> controller;
  final TvMenuThemeData theme;
  final CategoryTheme catTheme;

  const _AnimatedMenuBackground({
    required this.controller,
    required this.theme,
    required this.catTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (!theme.animated) {
      return Stack(
        children: [
          Positioned.fill(child: _TextureBackground(theme: theme)),
          Positioned.fill(
            child: _RadialWash(
              theme: theme,
              catTheme: catTheme,
              progress: 0,
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.background,
                      Color.lerp(
                          theme.background, theme.backgroundAccent, 0.7)!,
                      theme.background,
                    ],
                    stops: const [0, 0.55, 1],
                    transform: GradientRotation(controller.value * 6.28318),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: _TextureBackground(
                theme: theme,
                progress: controller.value,
              ),
            ),
            Positioned.fill(
              child: _RadialWash(
                theme: theme,
                catTheme: catTheme,
                progress: controller.value,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RadialWash extends StatelessWidget {
  final TvMenuThemeData theme;
  final CategoryTheme catTheme;
  final double progress;

  const _RadialWash({
    required this.theme,
    required this.catTheme,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final center = theme.animated
        ? Alignment(
            0.36 * sin(progress * 6.28318),
            0.28 * cos(progress * 6.28318),
          )
        : Alignment.center;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: theme.animated ? 1.55 : 1.35,
          colors: [
            theme.glowColor,
            Color.lerp(
              theme.background,
              catTheme.gradient[0],
              theme.isDark ? 0.12 : 0.08,
            )!,
            theme.background.withOpacity(theme.isDark ? 0.72 : 0.62),
          ],
          stops: const [0, 0.45, 1],
        ),
      ),
    );
  }
}

class _TextureBackground extends StatelessWidget {
  final TvMenuThemeData theme;
  final double progress;
  const _TextureBackground({required this.theme, this.progress = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TexturePainter(
        color: theme.textureColor,
        progress: progress,
        animated: theme.animated,
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool animated;
  const _TexturePainter({
    required this.color,
    required this.progress,
    required this.animated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.4
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    final drift = animated ? progress * spacing : 0.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + drift, y + drift), 0.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TexturePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.progress != progress ||
      oldDelegate.animated != animated;
}
