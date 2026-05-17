// lib/screens/menu_board_screen.dart
//
// TV menu board with an editorial alternating row layout.

import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/business_brand_mark.dart';
import '../widgets/combo_offer_showcase.dart';
import '../widgets/menu_item_row.dart';

List<String> _contentModesFrom(String value) {
  final modes = value
      .split(',')
      .map((mode) => mode.trim())
      .where((mode) => mode.isNotEmpty)
      .toList();
  if (modes.isEmpty || modes.contains('allCategories')) {
    return const ['category', 'comboOffers', 'todaysStar'];
  }
  return modes;
}

class _ContentSection {
  final String mode;
  final List<List<MenuItem>> groups;

  const _ContentSection({
    required this.mode,
    required this.groups,
  });
}

class MenuBoardScreen extends StatefulWidget {
  final DeviceConfig config;
  final DisplayConfig displayConfig;
  final Size screenSize;
  final Duration initialRevealDelay;
  final VoidCallback? onCycleComplete;

  const MenuBoardScreen({
    super.key,
    required this.config,
    required this.displayConfig,
    required this.screenSize,
    this.initialRevealDelay = Duration.zero,
    this.onCycleComplete,
  });

  @override
  State<MenuBoardScreen> createState() => _MenuBoardScreenState();
}

class _MenuBoardScreenState extends State<MenuBoardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _bgCtrl;
  Timer? _revealTimer;
  Timer? _pageTimer;
  List<MenuItem> _items = [];
  List<List<MenuItem>> _categoryGroups = [];
  List<_ContentSection> _sections = [];
  int _sectionIndex = 0;
  int _groupIndex = 0;
  int _pageIndex = 0;
  String _contentSignature = '';
  bool _contentReady = false;

  MenuCategory get _category =>
      widget.displayConfig.menuCategory ?? MenuCategory.all;
  String get _activeContentMode => _sections.isNotEmpty
      ? _sections[_sectionIndex].mode
      : _contentModesFrom(widget.displayConfig.contentMode).first;
  String get _sectionHeading {
    switch (_activeContentMode) {
      case 'veg':
        return 'Veg';
      case 'nonVeg':
        return 'Non Veg';
      case 'comboOffers':
        return 'Combo Offer';
      case 'todaysStar':
        return "Today's Star";
      case 'category':
        return _items.isNotEmpty
            ? (_items.first.categoryName ?? 'Menu')
            : 'Menu';
      case 'allCategories':
        return _items.isNotEmpty
            ? (_items.first.categoryName ?? 'Full Menu')
            : 'Full Menu';
      default:
        return 'Menu';
    }
  }

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
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _contentSignature = _buildContentSignature(widget.displayConfig.menuItems);
    if (widget.initialRevealDelay == Duration.zero) {
      _revealContent();
    } else {
      _revealTimer = Timer(widget.initialRevealDelay, _revealContent);
    }
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
        oldWidget.displayConfig.contentMode !=
            widget.displayConfig.contentMode ||
        oldWidget.config.menuTheme != widget.config.menuTheme ||
        oldWidget.displayConfig.showPrice != widget.displayConfig.showPrice ||
        oldWidget.displayConfig.showDescription !=
            widget.displayConfig.showDescription ||
        oldWidget.displayConfig.showProductImage !=
            widget.displayConfig.showProductImage ||
        oldWidget.displayConfig.showDietTags !=
            widget.displayConfig.showDietTags ||
        oldWidget.displayConfig.headingFontScale !=
            widget.displayConfig.headingFontScale ||
        oldWidget.displayConfig.nameFontScale !=
            widget.displayConfig.nameFontScale ||
        oldWidget.displayConfig.descriptionFontScale !=
            widget.displayConfig.descriptionFontScale ||
        oldWidget.displayConfig.priceFontScale !=
            widget.displayConfig.priceFontScale) {
      _contentSignature =
          _buildContentSignature(widget.displayConfig.menuItems);
      if (!_contentReady) return;
      _fadeCtrl.reset();
      _loadItems();
      _fadeCtrl.forward();
    }

    if (oldWidget.displayConfig.autoScrollIntervalSeconds !=
            widget.displayConfig.autoScrollIntervalSeconds &&
        _contentReady) {
      _startPageTimer();
    }
  }

  void _revealContent() {
    if (!mounted || _contentReady) return;
    _contentReady = true;
    _loadItems();
    _fadeCtrl.forward();
    _startPageTimer();
  }

  String _buildContentSignature(List<MenuItem> items) {
    return items
        .map(
          (item) =>
              '${item.id}:${item.name}:${item.price}:${item.originalPrice ?? ''}:${item.isAvailable}:${item.tags.join(',')}:${item.priceVariants.map((variant) => '${variant.label}-${variant.price}').join(',')}:${item.imageUrl ?? ''}:${item.categoryId ?? ''}:${item.categoryName ?? ''}:${item.comboItems.map((comboItem) => '${comboItem.product.id}-${comboItem.product.name}-${comboItem.product.price}-${comboItem.product.isAvailable}-${comboItem.quantity}-${comboItem.product.imageUrl ?? ''}').join(',')}',
        )
        .join('|');
  }

  void _loadItems() {
    final all = widget.displayConfig.menuItems;
    final modes = _contentModesFrom(widget.displayConfig.contentMode)
        .where((mode) => mode != 'allMedia' && mode != 'media')
        .toList();
    setState(() {
      _pageIndex = 0;
      _groupIndex = 0;
      _sectionIndex = 0;
      _sections = _buildContentSections(
        all,
        modes.isEmpty ? ['allCategories'] : modes,
      );
      _categoryGroups = _sections.isNotEmpty
          ? _sections.first.groups
          : _buildCategoryGroups(
              all,
              'allCategories',
            );
      _items = _categoryGroups.isNotEmpty ? _categoryGroups.first : all;
    });
  }

  List<_ContentSection> _buildContentSections(
    List<MenuItem> all,
    List<String> modes,
  ) {
    final sections = <_ContentSection>[];
    for (final mode in modes) {
      final sectionItems = switch (mode) {
        'veg' => all.where(
            (item) => item.tags.contains('veg') && item.comboItems.isEmpty,
          ),
        'nonVeg' => all.where(
            (item) => item.tags.contains('nonVeg') && item.comboItems.isEmpty,
          ),
        'comboOffers' => all.where((item) => item.comboItems.isNotEmpty),
        'todaysStar' => all.where(
            (item) =>
                item.isFeatured &&
                item.comboItems.isEmpty &&
                !_isAlreadyShownInSelectedCategory(item),
          ),
        _ => all.where((item) => item.comboItems.isEmpty),
      }
          .toList();
      if (sectionItems.isEmpty) continue;
      sections.add(
        _ContentSection(
          mode: mode,
          groups: _buildCategoryGroups(sectionItems, mode),
        ),
      );
    }
    return sections;
  }

  bool _isAlreadyShownInSelectedCategory(MenuItem item) {
    final selectedCategoryId = widget.displayConfig.selectedCategoryId;
    return selectedCategoryId != null && item.categoryId == selectedCategoryId;
  }

  List<List<MenuItem>> _buildCategoryGroups(List<MenuItem> all, String mode) {
    if (mode != 'allCategories' && mode != 'category') {
      return [
        _category == MenuCategory.all
            ? all
            : all.where((i) => i.category == _category).toList()
      ];
    }
    if (mode == 'category' && widget.displayConfig.selectedCategoryId != null) {
      return [all];
    }
    final groups = <String, List<MenuItem>>{};
    for (final item in all) {
      final key = item.categoryId?.toString() ?? item.categoryName ?? 'menu';
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups.values.where((items) => items.isNotEmpty).toList();
  }

  int _itemsPerPage(Size size) {
    return _MenuPageMetrics.forSize(
      size,
      headingFontScale: widget.displayConfig.headingFontScale,
    ).itemsPerPage;
  }

  void _startPageTimer() {
    final interval = widget.displayConfig.autoScrollIntervalSeconds ?? 8;
    _pageTimer?.cancel();
    _pageTimer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!mounted || _items.isEmpty) return;
      if (_activeContentMode == 'comboOffers') {
        final offersPerPage = ComboOfferShowcase.offersPerPageFor(
          widget.screenSize,
        );
        final pageCount = (_items.length / offersPerPage).ceil();
        if (pageCount <= 1) {
          _advanceSection();
          return;
        }
        setState(() {
          if (_pageIndex + 1 < pageCount) {
            _pageIndex++;
          } else {
            _setNextSection();
          }
        });
        return;
      }
      if (_activeContentMode == 'todaysStar') {
        if (_items.length <= 1) {
          _advanceSection();
          return;
        }
        setState(() {
          if (_pageIndex + 1 < _items.length) {
            _pageIndex++;
          } else {
            _setNextSection();
          }
        });
        return;
      }
      final itemsPerPage = _itemsPerPage(widget.screenSize);
      final pageCount = (_items.length / itemsPerPage).ceil();
      final visibleGroupCount =
          _categoryGroups.where((group) => group.isNotEmpty).length;
      if (pageCount <= 1 && visibleGroupCount <= 1) {
        _advanceSection();
        return;
      }
      setState(() {
        if (_pageIndex + 1 < pageCount) {
          _pageIndex++;
          return;
        }
        _pageIndex = 0;
        if (_categoryGroups.length > 1) {
          final nextGroupIndex = (_groupIndex + 1) % _categoryGroups.length;
          if (nextGroupIndex == 0 && _sections.length > 1) {
            _setNextSection();
          } else {
            _groupIndex = nextGroupIndex;
            _items = _categoryGroups[_groupIndex];
            if (nextGroupIndex == 0) _notifyCycleComplete();
          }
        } else {
          _setNextSection();
        }
      });
    });
  }

  void _advanceSection() {
    if (_sections.length <= 1) {
      _notifyCycleComplete();
      return;
    }
    setState(_setNextSection);
  }

  void _setNextSection() {
    final nextSectionIndex = (_sectionIndex + 1) % _sections.length;
    final cycleComplete = nextSectionIndex == 0 && _sections.length > 1;
    _sectionIndex = nextSectionIndex;
    _categoryGroups = _sections[_sectionIndex].groups;
    _groupIndex = 0;
    _pageIndex = 0;
    _items = _categoryGroups.isNotEmpty ? _categoryGroups.first : [];
    if (cycleComplete) _notifyCycleComplete();
  }

  void _notifyCycleComplete() {
    if (widget.onCycleComplete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCycleComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _fadeCtrl.dispose();
    _bgCtrl.dispose();
    _pageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.menuTheme(_themeType);
    final catTheme = _activeCategoryTheme;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: theme.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _AnimatedMenuBackground(
                controller: _bgCtrl,
                theme: theme,
                catTheme: catTheme,
              ),
            ),
            Positioned.fill(
              child: !_contentReady
                  ? const SizedBox.shrink()
                  : _items.isEmpty
                      ? _EmptyState(catTheme: catTheme, theme: theme)
                      : _activeContentMode == 'comboOffers'
                          ? ComboOfferShowcase(
                              combos: _items,
                              pageIndex: _pageIndex,
                              catTheme: catTheme,
                              theme: theme,
                              screenSize: widget.screenSize,
                              transitionStyle:
                                  widget.displayConfig.transitionStyle,
                              transitionSpeedSeconds:
                                  widget.displayConfig.transitionSpeedSeconds,
                              headingFontScale:
                                  widget.displayConfig.headingFontScale,
                              nameFontScale: widget.displayConfig.nameFontScale,
                              priceFontScale:
                                  widget.displayConfig.priceFontScale,
                              showPrice: widget.displayConfig.showPrice,
                              showProductImage:
                                  widget.displayConfig.showProductImage,
                            )
                          : _activeContentMode == 'todaysStar'
                              ? _TodaysStarShowcase(
                                  items: _items,
                                  pageIndex: _pageIndex,
                                  screenSize: widget.screenSize,
                                  transitionStyle:
                                      widget.displayConfig.transitionStyle,
                                  transitionSpeedSeconds: widget
                                      .displayConfig.transitionSpeedSeconds,
                                  showPrice: widget.displayConfig.showPrice,
                                  showProductImage:
                                      widget.displayConfig.showProductImage,
                                  headingFontScale:
                                      widget.displayConfig.headingFontScale,
                                  nameFontScale:
                                      widget.displayConfig.nameFontScale,
                                  priceFontScale:
                                      widget.displayConfig.priceFontScale,
                                )
                              : _PagedMenu(
                                  items: _items,
                                  pageIndex: _pageIndex,
                                  groupIndex: _groupIndex,
                                  catTheme: catTheme,
                                  theme: theme,
                                  screenSize: widget.screenSize,
                                  transitionStyle:
                                      widget.displayConfig.transitionStyle,
                                  transitionSpeedSeconds: widget
                                      .displayConfig.transitionSpeedSeconds,
                                  showPrice: widget.displayConfig.showPrice,
                                  showDescription:
                                      widget.displayConfig.showDescription,
                                  showProductImage:
                                      widget.displayConfig.showProductImage,
                                  showDietTags:
                                      widget.displayConfig.showDietTags,
                                  heading: _sectionHeading,
                                  sectionMode: _activeContentMode,
                                  headingFontScale:
                                      widget.displayConfig.headingFontScale,
                                  nameFontScale:
                                      widget.displayConfig.nameFontScale,
                                  descriptionFontScale:
                                      widget.displayConfig.descriptionFontScale,
                                  priceFontScale:
                                      widget.displayConfig.priceFontScale,
                                ),
            ),
            if (_contentReady && _shouldShowBrandMark)
              BusinessBrandMark(
                businessName: widget.displayConfig.showCompanyName
                    ? widget.config.businessName
                    : null,
                logoUrl: widget.displayConfig.showLogo
                    ? widget.config.businessLogoUrl
                    : null,
                darkBackdrop: theme.isDark,
              ),
          ],
        ),
      ),
    );
  }

  bool get _shouldShowBrandMark {
    final hasVisibleName = widget.displayConfig.showCompanyName &&
        (widget.config.businessName?.trim().isNotEmpty ?? false);
    final hasVisibleLogo = widget.displayConfig.showLogo &&
        (widget.config.businessLogoUrl?.trim().isNotEmpty ?? false);
    return hasVisibleName || hasVisibleLogo;
  }

  CategoryTheme get _activeCategoryTheme {
    final mode = _activeContentMode;
    final baseCatTheme = AppTheme.categoryThemes[mode] ??
        AppTheme.categoryThemes[_category.name] ??
        AppTheme.categoryThemes['all']!;
    if (mode == 'veg' || mode == 'nonVeg') return baseCatTheme;
    return AppTheme.colorizedCategoryTheme(
      baseCatTheme,
      widget.config.themeColor.isNotEmpty
          ? widget.config.themeColor
          : widget.displayConfig.themeColor,
    );
  }
}

class _TodaysStarShowcase extends StatelessWidget {
  final List<MenuItem> items;
  final int pageIndex;
  final Size screenSize;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final bool showPrice;
  final bool showProductImage;
  final double headingFontScale;
  final double nameFontScale;
  final double priceFontScale;

  const _TodaysStarShowcase({
    required this.items,
    required this.pageIndex,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
    required this.showPrice,
    required this.showProductImage,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.priceFontScale,
  });

  int get _itemsPerPage => 1;

  @override
  Widget build(BuildContext context) {
    final pageCount =
        (items.length / _itemsPerPage).ceil().clamp(1, items.length);
    final safePageIndex = pageIndex % pageCount;
    final start = safePageIndex * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, items.length);
    final pageItems = items.sublist(start, end);
    final longestName = pageItems.fold<int>(
      8,
      (value, item) => max(value, item.name.length),
    );
    final nameSize = ((screenSize.width * 0.054) * nameFontScale)
        .clamp(36.0, longestName > 20 ? 78.0 : 96.0);
    final priceSize =
        ((screenSize.width * 0.034) * priceFontScale).clamp(26.0, 60.0);

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
      child: Stack(
        key: ValueKey('todays-star-$safePageIndex-${items.length}'),
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _ComicStarBackground()),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (screenSize.width * 0.06).clamp(34.0, 92.0),
                vertical: (screenSize.height * 0.06).clamp(28.0, 58.0),
              ),
              child: Column(
                children: [
                  Text(
                    "TODAY'S STAR",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(
                      fontSize: ((screenSize.width * 0.044) * headingFontScale)
                          .clamp(32.0, 80.0),
                      color: const Color(0xFFFFD21F),
                      letterSpacing: 1.2,
                      shadows: const [
                        Shadow(
                          color: Color(0xFFE51F2D),
                          offset: Offset(3, 0),
                        ),
                        Shadow(
                          color: Color(0xFFE51F2D),
                          offset: Offset(-3, 0),
                        ),
                        Shadow(
                          color: Color(0xFFE51F2D),
                          offset: Offset(0, 3),
                        ),
                        Shadow(
                          color: Color(0xFFE51F2D),
                          offset: Offset(0, -3),
                        ),
                        Shadow(
                          color: Color(0x33000000),
                          offset: Offset(6, 6),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: (screenSize.height * 0.035).clamp(18.0, 36.0)),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: pageItems
                          .map(
                            (item) => Expanded(
                              child: _TodaysStarProduct(
                                item: item,
                                nameSize: nameSize,
                                priceSize: priceSize,
                                showPrice: showPrice,
                                showProductImage: showProductImage,
                                maxImageSize: (screenSize.height * 0.38)
                                    .clamp(220.0, 430.0),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysStarProduct extends StatelessWidget {
  final MenuItem item;
  final double nameSize;
  final double priceSize;
  final bool showPrice;
  final bool showProductImage;
  final double maxImageSize;

  const _TodaysStarProduct({
    required this.item,
    required this.nameSize,
    required this.priceSize,
    required this.showPrice,
    required this.showProductImage,
    required this.maxImageSize,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final medallionSize = min(
          maxImageSize,
          min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.56),
        );
        final product = FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProductImage) ...[
                  _RedDottedProductCircle(
                    item: item,
                    size: medallionSize,
                  ),
                  SizedBox(height: medallionSize * 0.08),
                ],
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(
                    fontSize: nameSize,
                    color: const Color(0xFFFFF04A),
                    letterSpacing: 0.8,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0xFFE51F2D),
                        offset: Offset(3, 0),
                      ),
                      Shadow(
                        color: Color(0xFFE51F2D),
                        offset: Offset(-3, 0),
                      ),
                      Shadow(
                        color: Color(0xFFE51F2D),
                        offset: Offset(0, 3),
                      ),
                      Shadow(
                        color: Color(0xFFE51F2D),
                        offset: Offset(0, -3),
                      ),
                      Shadow(
                        color: Color(0x55000000),
                        offset: Offset(5, 5),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showPrice) ...[
                  const SizedBox(height: 12),
                  _TodaysStarPriceText(item: item, fontSize: priceSize),
                ],
              ],
            ),
          ),
        );

        return _UnavailableTreatment(
          enabled: !item.isAvailable,
          child: product,
        );
      },
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

class _RedDottedProductCircle extends StatelessWidget {
  final MenuItem item;
  final double size;

  const _RedDottedProductCircle({
    required this.item,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = size * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: const _DottedCirclePainter(),
          ),
          Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF2D0),
              border: Border.all(color: Colors.white, width: size * 0.025),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const _StarPlaceholder(),
                      errorWidget: (_, __, ___) => const _StarPlaceholder(),
                    )
                  : const _StarPlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysStarPriceText extends StatelessWidget {
  final MenuItem item;
  final double fontSize;

  const _TodaysStarPriceText({
    required this.item,
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
      textAlign: TextAlign.center,
      style: GoogleFonts.bangers(
        fontSize: item.priceVariants.isNotEmpty ? fontSize * 0.74 : fontSize,
        color: const Color(0xFF25E6FF),
        letterSpacing: 0.7,
        shadows: const [
          Shadow(
            color: Color(0xFF073B8E),
            offset: Offset(3, 0),
          ),
          Shadow(
            color: Color(0xFF073B8E),
            offset: Offset(-3, 0),
          ),
          Shadow(
            color: Color(0xFF073B8E),
            offset: Offset(0, 3),
          ),
          Shadow(
            color: Color(0xFF073B8E),
            offset: Offset(0, -3),
          ),
          Shadow(
            color: Color(0x66000000),
            offset: Offset(5, 5),
            blurRadius: 1,
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StarPlaceholder extends StatelessWidget {
  const _StarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFFE6B1),
      child: Center(
        child: Text(
          'STAR',
          style: TextStyle(
            color: Color(0xFFC62828),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ComicStarBackground extends StatelessWidget {
  const _ComicStarBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF04A4A),
      child: CustomPaint(
        painter: _ComicStarBackgroundPainter(),
      ),
    );
  }
}

class _ComicStarBackgroundPainter extends CustomPainter {
  const _ComicStarBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.44);
    const rayCount = 28;
    final radius = size.longestSide * 0.78;
    final redPaint = Paint()
      ..color = const Color(0xFFFF5A5A).withValues(alpha: 0.46)
      ..style = PaintingStyle.fill;
    final paleRedPaint = Paint()
      ..color = const Color(0xFFFF7A7A).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFFE51F2D).withValues(alpha: 0.22)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < rayCount; i++) {
      final a1 = (i / rayCount) * pi * 2;
      final a2 = ((i + 0.58) / rayCount) * pi * 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + cos(a1) * radius, center.dy + sin(a1) * radius)
        ..lineTo(center.dx + cos(a2) * radius, center.dy + sin(a2) * radius)
        ..close();
      canvas.drawPath(path, i.isEven ? redPaint : paleRedPaint);
      if (i.isEven) canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()
      ..color = const Color(0xFFFFD1D1).withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    for (var y = 8.0; y < size.height; y += spacing) {
      for (var x = 8.0; x < size.width; x += spacing) {
        final dist = (Offset(x, y) - center).distance;
        final dotRadius = dist < radius * 0.55 ? 2.2 : 1.2;
        canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DottedCirclePainter extends CustomPainter {
  const _DottedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final basePaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center.translate(0, 8), radius * 0.94, shadowPaint);
    canvas.drawCircle(center, radius * 0.92, basePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFFFFF0BE).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    const ringCount = 8;
    for (var ring = 1; ring <= ringCount; ring++) {
      final ringRadius = radius * (0.16 + ring * 0.09);
      final dots = (ringRadius / 5).round().clamp(10, 54);
      for (var i = 0; i < dots; i++) {
        final angle = (i / dots) * pi * 2 + ring * 0.23;
        canvas.drawCircle(
          Offset(
            center.dx + cos(angle) * ringRadius,
            center.dy + sin(angle) * ringRadius,
          ),
          radius * 0.012,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  final bool showPrice;
  final bool showDescription;
  final bool showProductImage;
  final bool showDietTags;
  final String heading;
  final String sectionMode;
  final double headingFontScale;
  final double nameFontScale;
  final double descriptionFontScale;
  final double priceFontScale;

  const _PagedMenu({
    required this.items,
    required this.pageIndex,
    required this.groupIndex,
    required this.catTheme,
    required this.theme,
    required this.screenSize,
    required this.transitionStyle,
    required this.transitionSpeedSeconds,
    required this.showPrice,
    required this.showDescription,
    required this.showProductImage,
    required this.showDietTags,
    required this.heading,
    required this.sectionMode,
    required this.headingFontScale,
    required this.nameFontScale,
    required this.descriptionFontScale,
    required this.priceFontScale,
  });

  static const double _verticalPadding = 76;
  static const double _headingGap = 14;

  double get _baseRowHeight => (screenSize.width * 0.12).clamp(170.0, 220.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : screenSize.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : screenSize.height,
        );
        final metrics = _MenuPageMetrics.forSize(
          viewportSize,
          headingFontScale: headingFontScale,
        );
        final itemsPerPage = metrics.itemsPerPage;
        final pageCount =
            (items.length / itemsPerPage).ceil().clamp(1, items.length);
        final safePageIndex = pageIndex % pageCount;
        final start = safePageIndex * itemsPerPage;
        final end = (start + itemsPerPage).clamp(0, items.length);
        final pageItems = items.sublist(start, end);
        final dividerCount = pageItems.length > 1 ? pageItems.length - 1 : 0;
        final stretchedRowHeight =
            (metrics.availableRowsHeight - dividerCount) / pageItems.length;
        final sparseRowHeight =
            (viewportSize.height * 0.34).clamp(_baseRowHeight, 380.0);
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
              screenWidth: viewportSize.width,
              rowHeight: rowHeight,
              showPrice: showPrice,
              showDescription: showDescription,
              showProductImage: showProductImage,
              showDietTags: showDietTags,
              nameFontScale: nameFontScale,
              descriptionFontScale: descriptionFontScale,
              priceFontScale: priceFontScale,
            ),
          );

          if (i < pageItems.length - 1) {
            rows.add(_RowDivider(theme: theme));
          }
        }

        return AnimatedSwitcher(
          duration:
              Duration(milliseconds: (transitionSpeedSeconds * 1000).round()),
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
              children: [
                _StandardSectionHeading(
                  text: heading,
                  sectionMode: sectionMode,
                  theme: theme,
                  catTheme: catTheme,
                  showDietTags: showDietTags,
                  fontScale: headingFontScale,
                  screenWidth: viewportSize.width,
                  height: metrics.headingHeight,
                ),
                const SizedBox(height: _headingGap),
                ...rows,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuPageMetrics {
  final double availableRowsHeight;
  final double headingHeight;
  final int itemsPerPage;

  const _MenuPageMetrics({
    required this.availableRowsHeight,
    required this.headingHeight,
    required this.itemsPerPage,
  });

  factory _MenuPageMetrics.forSize(
    Size size, {
    required double headingFontScale,
  }) {
    const dividerHeight = 1.0;
    final baseRowHeight = (size.width * 0.12).clamp(170.0, 220.0);
    final headingFontSize =
        ((size.width * 0.034) * headingFontScale).clamp(30.0, 68.0);
    final headingHeight = headingFontSize * 1.25;
    final headingBlockHeight = headingHeight + _PagedMenu._headingGap;
    final availableRowsHeight =
        (size.height - _PagedMenu._verticalPadding - headingBlockHeight)
            .clamp(baseRowHeight, size.height);
    final count = ((availableRowsHeight + dividerHeight) /
            (baseRowHeight + dividerHeight))
        .floor();

    return _MenuPageMetrics(
      availableRowsHeight: availableRowsHeight,
      headingHeight: headingHeight,
      itemsPerPage: count.clamp(1, 6),
    );
  }
}

class _StandardSectionHeading extends StatelessWidget {
  final String text;
  final String sectionMode;
  final TvMenuThemeData theme;
  final CategoryTheme catTheme;
  final bool showDietTags;
  final double fontScale;
  final double screenWidth;
  final double height;

  const _StandardSectionHeading({
    required this.text,
    required this.sectionMode,
    required this.theme,
    required this.catTheme,
    required this.showDietTags,
    required this.fontScale,
    required this.screenWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize:
                        ((screenWidth * 0.034) * fontScale).clamp(30.0, 68.0),
                    fontWeight: FontWeight.w800,
                    color: theme.primaryText,
                    height: 1,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: catTheme.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                if (showDietTags &&
                    (sectionMode == 'veg' || sectionMode == 'nonVeg')) ...[
                  SizedBox(width: (screenWidth * 0.012).clamp(10.0, 22.0)),
                  _DietSectionSymbol(
                    mode: sectionMode,
                    size: ((screenWidth * 0.018) * fontScale).clamp(22.0, 38.0),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DietSectionSymbol extends StatelessWidget {
  final String mode;
  final double size;

  const _DietSectionSymbol({required this.mode, required this.size});

  @override
  Widget build(BuildContext context) {
    final isVeg = mode == 'veg';
    final color = isVeg ? AppTheme.vegGreen : const Color(0xFFB33A2B);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: max(2.0, size * 0.08)),
        borderRadius: BorderRadius.circular(size * 0.12),
      ),
      child: Center(
        child: isVeg
            ? Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
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
