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
import '../widgets/notice_showcase.dart';
import '../widgets/offer_showcase.dart';

List<String> _contentModesFrom(String value) {
  final modes = value
      .split(',')
      .map((mode) => mode.trim())
      .where((mode) => mode.isNotEmpty)
      .toList();
  if (modes.isEmpty || modes.contains('allCategories')) {
    return const ['category', 'comboOffers', 'offers', 'notices', 'todaysStar'];
  }
  return modes;
}

class _ContentSection {
  final String mode;
  final List<List<MenuItem>> groups;
  final List<NoticeItem> notices;

  const _ContentSection({
    required this.mode,
    required this.groups,
    this.notices = const [],
  });
}

class MenuBoardScreen extends StatefulWidget {
  final DeviceConfig config;
  final DisplayConfig displayConfig;
  final Size screenSize;
  final Duration initialRevealDelay;
  final bool isActive;
  final VoidCallback? onCycleComplete;

  const MenuBoardScreen({
    super.key,
    required this.config,
    required this.displayConfig,
    required this.screenSize,
    this.initialRevealDelay = Duration.zero,
    this.isActive = true,
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
  List<NoticeItem> get _activeNotices =>
      _sections.isNotEmpty ? _sections[_sectionIndex].notices : const [];
  String get _sectionHeading {
    final language = widget.displayConfig.displayLanguage;
    switch (_activeContentMode) {
      case 'veg':
        return _localizedMenuText(language, 'veg');
      case 'nonVeg':
        return _localizedMenuText(language, 'nonVeg');
      case 'comboOffers':
        return _localizedMenuText(language, 'comboOffer');
      case 'offers':
        return _localizedMenuText(language, 'offers');
      case 'notices':
        return _localizedMenuText(language, 'notices');
      case 'todaysStar':
        return _localizedMenuText(language, 'todaysStar');
      case 'category':
        return _items.isNotEmpty
            ? (_items.first.categoryName ??
                _localizedMenuText(language, 'menu'))
            : _localizedMenuText(language, 'menu');
      case 'allCategories':
        return _items.isNotEmpty
            ? (_items.first.categoryName ??
                _localizedMenuText(language, 'fullMenu'))
            : _localizedMenuText(language, 'fullMenu');
      default:
        return _localizedMenuText(language, 'menu');
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

    _contentSignature = _buildContentSignature(
      widget.displayConfig.menuItems,
      widget.displayConfig.notices,
    );
    if (widget.initialRevealDelay == Duration.zero) {
      _revealContent();
    } else {
      _revealTimer = Timer(widget.initialRevealDelay, _revealContent);
    }
  }

  @override
  void didUpdateWidget(MenuBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _bgCtrl.repeat();
        if (_contentReady) _startPageTimer();
      } else {
        _pageTimer?.cancel();
        _pageTimer = null;
        _bgCtrl.stop();
      }
    }
    if (oldWidget.displayConfig.menuCategory !=
            widget.displayConfig.menuCategory ||
        oldWidget.displayConfig.themeOverride !=
            widget.displayConfig.themeOverride ||
        _contentSignature !=
            _buildContentSignature(
              widget.displayConfig.menuItems,
              widget.displayConfig.notices,
            ) ||
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
        oldWidget.displayConfig.showComboItemQuantity !=
            widget.displayConfig.showComboItemQuantity ||
        oldWidget.displayConfig.headingFontScale !=
            widget.displayConfig.headingFontScale ||
        oldWidget.displayConfig.nameFontScale !=
            widget.displayConfig.nameFontScale ||
        oldWidget.displayConfig.descriptionFontScale !=
            widget.displayConfig.descriptionFontScale ||
        oldWidget.displayConfig.priceFontScale !=
            widget.displayConfig.priceFontScale) {
      _contentSignature = _buildContentSignature(
        widget.displayConfig.menuItems,
        widget.displayConfig.notices,
      );
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

  String _buildContentSignature(
      List<MenuItem> items, List<NoticeItem> notices) {
    final itemSignature = items
        .map(
          (item) =>
              '${item.id}:${item.name}:${item.price}:${item.originalPrice ?? ''}:${item.isAvailable}:${item.tags.join(',')}:${item.priceVariants.map((variant) => '${variant.label}-${variant.price}').join(',')}:${item.imageUrl ?? ''}:${item.categoryId ?? ''}:${item.categoryName ?? ''}:${item.comboItems.map((comboItem) => '${comboItem.product.id}-${comboItem.product.name}-${comboItem.product.price}-${comboItem.product.isAvailable}-${comboItem.quantity}-${comboItem.variantLabel ?? ''}-${comboItem.variantPrice ?? ''}-${comboItem.product.imageUrl ?? ''}').join(',')}',
        )
        .join('|');
    final noticeSignature = notices
        .map((notice) =>
            '${notice.id}:${notice.content}:${notice.createdAt?.toIso8601String() ?? ''}')
        .join('|');
    return '$itemSignature::$noticeSignature';
  }

  void _loadItems() {
    final all = widget.displayConfig.menuItems;
    final modes = _contentModesFrom(widget.displayConfig.contentMode)
        .where((mode) => mode != 'allMedia' && mode != 'media')
        .toList();
    final effectiveModes = modes.isEmpty ? ['allCategories'] : modes;
    setState(() {
      _pageIndex = 0;
      _groupIndex = 0;
      _sectionIndex = 0;
      _sections = _buildContentSections(
        all,
        widget.displayConfig.notices,
        effectiveModes,
      );
      _categoryGroups = _sections.isNotEmpty
          ? _sections.first.groups
          : effectiveModes.length == 1 && effectiveModes.first == 'notices'
              ? const []
              : _buildCategoryGroups(
                  all,
                  'allCategories',
                );
      _items = _categoryGroups.isNotEmpty ? _categoryGroups.first : all;
    });
  }

  List<_ContentSection> _buildContentSections(
    List<MenuItem> all,
    List<NoticeItem> notices,
    List<String> modes,
  ) {
    final sections = <_ContentSection>[];
    for (final mode in modes) {
      if (mode == 'notices') {
        final activeNotices = notices
            .where((notice) => notice.content.trim().isNotEmpty)
            .toList();
        if (activeNotices.isEmpty) continue;
        sections.add(
          _ContentSection(
            mode: mode,
            groups: const [[]],
            notices: activeNotices,
          ),
        );
        continue;
      }
      final sectionItems = switch (mode) {
        'veg' => all.where(
            (item) => item.tags.contains('veg') && item.comboItems.isEmpty,
          ),
        'nonVeg' => all.where(
            (item) => item.tags.contains('nonVeg') && item.comboItems.isEmpty,
          ),
        'comboOffers' => all.where(
            (item) =>
                item.comboItems.isNotEmpty && item.categoryName != 'Offers',
          ),
        'offers' => all.where((item) => item.categoryName == 'Offers'),
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
    if (!widget.isActive) return;
    final interval = widget.displayConfig.autoScrollIntervalSeconds ?? 8;
    _pageTimer?.cancel();
    _pageTimer = Timer.periodic(Duration(seconds: interval), (_) {
      if (!mounted) return;
      if (_activeContentMode == 'notices') {
        if (_activeNotices.length <= 1) {
          _advanceSection();
          return;
        }
        setState(() {
          if (_pageIndex + 1 < _activeNotices.length) {
            _pageIndex++;
          } else {
            _setNextSection();
          }
        });
        return;
      }
      if (_items.isEmpty) return;
      if (_activeContentMode == 'comboOffers' ||
          _activeContentMode == 'offers') {
        final pageCount = _activeContentMode == 'offers'
            ? OfferShowcase.pageCountFor(_items, widget.screenSize)
            : (_items.length /
                    ComboOfferShowcase.offersPerPageFor(widget.screenSize))
                .ceil();
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
                  : _activeContentMode == 'notices'
                      ? NoticeShowcase(
                          notices: _activeNotices,
                          pageIndex: _pageIndex,
                          screenSize: widget.screenSize,
                          transitionSpeedSeconds:
                              widget.displayConfig.transitionSpeedSeconds,
                        )
                      : _items.isEmpty
                          ? _EmptyState(
                              catTheme: catTheme,
                              theme: theme,
                              displayLanguage:
                                  widget.displayConfig.displayLanguage,
                            )
                          : _activeContentMode == 'comboOffers'
                              ? ComboOfferShowcase(
                                  combos: _items,
                                  pageIndex: _pageIndex,
                                  catTheme: catTheme,
                                  theme: theme,
                                  screenSize: widget.screenSize,
                                  transitionStyle:
                                      widget.displayConfig.transitionStyle,
                                  transitionSpeedSeconds: widget
                                      .displayConfig.transitionSpeedSeconds,
                                  headingFontScale:
                                      widget.displayConfig.headingFontScale,
                                  nameFontScale:
                                      widget.displayConfig.nameFontScale,
                                  priceFontScale:
                                      widget.displayConfig.priceFontScale,
                                  showPrice: widget.displayConfig.showPrice,
                                  showProductImage:
                                      widget.displayConfig.showProductImage,
                                  showComboItemQuantity: widget
                                      .displayConfig.showComboItemQuantity,
                                  displayLanguage:
                                      widget.displayConfig.displayLanguage,
                                  businessName: widget.config.businessName,
                                  businessLogoUrl: widget.displayConfig.showLogo
                                      ? widget.config.businessLogoUrl
                                      : null,
                                )
                              : _activeContentMode == 'offers'
                                  ? OfferShowcase(
                                      offers: _items,
                                      pageIndex: _pageIndex,
                                      theme: theme,
                                      screenSize: widget.screenSize,
                                      transitionStyle:
                                          widget.displayConfig.transitionStyle,
                                      transitionSpeedSeconds: widget
                                          .displayConfig.transitionSpeedSeconds,
                                      headingFontScale:
                                          widget.displayConfig.headingFontScale,
                                      nameFontScale:
                                          widget.displayConfig.nameFontScale,
                                      priceFontScale:
                                          widget.displayConfig.priceFontScale,
                                      showPrice: widget.displayConfig.showPrice,
                                      showProductImage:
                                          widget.displayConfig.showProductImage,
                                      displayLanguage:
                                          widget.displayConfig.displayLanguage,
                                      businessName: widget.config.businessName,
                                      businessLogoUrl:
                                          widget.displayConfig.showLogo
                                              ? widget.config.businessLogoUrl
                                              : null,
                                    )
                                  : _activeContentMode == 'todaysStar'
                                      ? _TodaysStarShowcase(
                                          items: _items,
                                          pageIndex: _pageIndex,
                                          screenSize: widget.screenSize,
                                          transitionStyle: widget
                                              .displayConfig.transitionStyle,
                                          transitionSpeedSeconds: widget
                                              .displayConfig
                                              .transitionSpeedSeconds,
                                          showPrice:
                                              widget.displayConfig.showPrice,
                                          showProductImage: widget
                                              .displayConfig.showProductImage,
                                          headingFontScale: widget
                                              .displayConfig.headingFontScale,
                                          nameFontScale: widget
                                              .displayConfig.nameFontScale,
                                          priceFontScale: widget
                                              .displayConfig.priceFontScale,
                                          displayLanguage: widget
                                              .displayConfig.displayLanguage,
                                        )
                                      : _PagedMenu(
                                          items: _items,
                                          pageIndex: _pageIndex,
                                          groupIndex: _groupIndex,
                                          catTheme: catTheme,
                                          theme: theme,
                                          screenSize: widget.screenSize,
                                          transitionStyle: widget
                                              .displayConfig.transitionStyle,
                                          transitionSpeedSeconds: widget
                                              .displayConfig
                                              .transitionSpeedSeconds,
                                          showPrice:
                                              widget.displayConfig.showPrice,
                                          showDescription: widget
                                              .displayConfig.showDescription,
                                          showProductImage: widget
                                              .displayConfig.showProductImage,
                                          showDietTags:
                                              widget.displayConfig.showDietTags,
                                          heading: _sectionHeading,
                                          sectionMode: _activeContentMode,
                                          displayLanguage: widget
                                              .displayConfig.displayLanguage,
                                          headingFontScale: widget
                                              .displayConfig.headingFontScale,
                                          nameFontScale: widget
                                              .displayConfig.nameFontScale,
                                          descriptionFontScale: widget
                                              .displayConfig
                                              .descriptionFontScale,
                                          priceFontScale: widget
                                              .displayConfig.priceFontScale,
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
    if (_activeContentMode == 'comboOffers') return false;
    if (_activeContentMode == 'notices') return false;
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

bool _isMalayalam(String language) => language.toLowerCase() == 'malayalam';

String _localizedMenuText(String language, String key) {
  if (_isMalayalam(language)) {
    return switch (key) {
      'veg' => 'വെജ്',
      'nonVeg' => 'നോൺ വെജ്',
      'comboOffer' => 'കോംബോ ഓഫർ',
      'offers' => 'ഓഫറുകൾ',
      'todaysStar' => 'ഇന്നത്തെ താരം',
      'menu' => 'മെനു',
      'fullMenu' => 'മുഴുവൻ മെനു',
      'addItems' => 'ആപ്പിൽ നിന്ന് ഇനങ്ങൾ ചേർക്കുക',
      'newProducts' => 'പുതിയ ഉൽപ്പന്നങ്ങളും മീഡിയയും ഇവിടെ കാണിക്കും.',
      _ => key,
    };
  }
  return switch (key) {
    'veg' => 'Veg',
    'nonVeg' => 'Non Veg',
    'comboOffer' => 'Combo Offer',
    'offers' => 'Offers',
    'notices' => 'Notices',
    'todaysStar' => "Today's Star",
    'menu' => 'Menu',
    'fullMenu' => 'Full Menu',
    'addItems' => 'Add items from the app',
    'newProducts' => 'New products and media will appear here automatically.',
    _ => key,
  };
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
  final String displayLanguage;

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
    required this.displayLanguage,
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
    final nameSize = ((screenSize.width * 0.040) * nameFontScale)
        .clamp(28.0, longestName > 20 ? 58.0 : 72.0);
    final priceSize =
        ((screenSize.width * 0.032) * priceFontScale).clamp(24.0, 54.0);

    final productKey = ValueKey(
      'todays-star-products-$safePageIndex-${pageItems.map((item) => item.id).join('-')}',
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: _TodaysSpecialPosterBackground()),
        const Positioned.fill(child: _PosterGarnishLayer()),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (screenSize.width * 0.055).clamp(30.0, 84.0),
              vertical: (screenSize.height * 0.035).clamp(20.0, 42.0),
            ),
            child: Column(
              children: [
                _TodaysSpecialTitle(
                  screenWidth: screenSize.width,
                  fontScale: headingFontScale,
                  language: displayLanguage,
                ),
                SizedBox(
                  height: (screenSize.height * 0.016).clamp(10.0, 18.0),
                ),
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: (transitionSpeedSeconds * 1000).round(),
                      ),
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
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'zoom':
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.98, end: 1)
                                  .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'flip':
                            return RotationTransition(
                              turns: Tween<double>(begin: -0.01, end: 0)
                                  .animate(animation),
                              child: FadeTransition(
                                  opacity: animation, child: child),
                            );
                          case 'fade':
                          default:
                            return FadeTransition(
                                opacity: animation, child: child);
                        }
                      },
                      child: RepaintBoundary(
                        key: productKey,
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
                                    maxImageSize: min(
                                      screenSize.width * 0.46,
                                      screenSize.height * 0.54,
                                    ).clamp(260.0, 560.0),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        final imageSize = min(
          maxImageSize,
          min(constraints.maxWidth * 0.62, constraints.maxHeight * 0.62),
        );
        final product = FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProductImage) ...[
                  _PosterProductImage(
                    item: item,
                    size: imageSize,
                  ),
                  SizedBox(height: imageSize * 0.035),
                ],
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: nameSize,
                    color: Colors.white,
                    letterSpacing: 0,
                    height: 0.98,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(
                        color: Color(0xAA000000),
                        offset: Offset(0, 8),
                        blurRadius: 18,
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

class _PosterProductImage extends StatelessWidget {
  final MenuItem item;
  final double size;

  const _PosterProductImage({
    required this.item,
    required this.size,
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
            bottom: size * 0.02,
            child: Container(
              width: size * 0.82,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(size),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xCC000000),
                    blurRadius: 36,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.08),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 34,
                  offset: Offset(0, 24),
                ),
                BoxShadow(
                  color: Color(0x55FF8A00),
                  blurRadius: 42,
                  spreadRadius: -12,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFF151515)),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.contain,
                      fadeInDuration: const Duration(milliseconds: 120),
                      fadeOutDuration: Duration.zero,
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
      style: GoogleFonts.montserrat(
        fontSize: item.priceVariants.isNotEmpty ? fontSize * 0.74 : fontSize,
        color: const Color(0xFFFF9B16),
        letterSpacing: 0,
        fontWeight: FontWeight.w900,
        shadows: const [
          Shadow(
            color: Color(0xAA000000),
            offset: Offset(0, 8),
            blurRadius: 18,
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
      color: Color(0xFF202020),
      child: Center(
        child: Text(
          'SPECIAL',
          style: TextStyle(
            color: Color(0xFFFF9B16),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _TodaysSpecialTitle extends StatelessWidget {
  final double screenWidth;
  final double fontScale;
  final String language;

  const _TodaysSpecialTitle({
    required this.screenWidth,
    required this.fontScale,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    if (_isMalayalam(language)) {
      final fontSize = ((screenWidth * 0.076) * fontScale).clamp(48.0, 124.0);
      return SizedBox(
        width: double.infinity,
        height: (fontSize * 1.45).clamp(120.0, 220.0),
        child: Center(
          child: Text(
            _localizedMenuText(language, 'todaysStar'),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansMalayalam(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.w900,
              height: 1,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  offset: Offset(0, 10),
                  blurRadius: 22,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final todaySize = ((screenWidth * 0.056) * fontScale).clamp(42.0, 100.0);
    final scriptSize = ((screenWidth * 0.112) * fontScale).clamp(86.0, 190.0);
    final menuSize = ((screenWidth * 0.062) * fontScale).clamp(48.0, 112.0);

    return SizedBox(
      width: double.infinity,
      height: (scriptSize * 1.38).clamp(130.0, 250.0),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: scriptSize * 0.06,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: todaySize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  letterSpacing: 0,
                ),
                children: const [
                  TextSpan(
                    text: 'TODAY',
                    style: TextStyle(color: Color(0xFFFFDB1E)),
                  ),
                  TextSpan(
                    text: '.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: todaySize * 0.50,
            child: Text(
              'Special',
              textAlign: TextAlign.center,
              style: GoogleFonts.greatVibes(
                fontSize: scriptSize,
                color: Colors.white,
                height: 0.84,
                shadows: const [
                  Shadow(
                    color: Color(0xCC000000),
                    offset: Offset(0, 10),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: scriptSize * 0.84,
            child: Text(
              'menu',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: menuSize,
                color: const Color(0xFFFF8A00),
                fontWeight: FontWeight.w500,
                height: 0.9,
                letterSpacing: 0,
                shadows: const [
                  Shadow(
                    color: Color(0x99000000),
                    offset: Offset(0, 8),
                    blurRadius: 18,
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

class _TodaysSpecialPosterBackground extends StatelessWidget {
  const _TodaysSpecialPosterBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF070707),
      child: CustomPaint(
        painter: _TodaysSpecialPosterBackgroundPainter(),
      ),
    );
  }
}

class _TodaysSpecialPosterBackgroundPainter extends CustomPainter {
  const _TodaysSpecialPosterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF050505),
          Color(0xFF151515),
          Color(0xFF110A20),
        ],
        stops: [0, 0.58, 1],
      ).createShader(rect);
    canvas.drawRect(rect, base);

    final purpleWash = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.78),
        radius: 1.1,
        colors: [
          const Color(0xFF2D0D62).withValues(alpha: 0.70),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, purpleWash);

    final smokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.24 + i * 0.075);
      final path = Path()..moveTo(-size.width * 0.05, y);
      for (var x = -size.width * 0.05; x <= size.width * 1.05; x += 80) {
        path.quadraticBezierTo(
          x + 36,
          y + sin(i + x * 0.015) * 34,
          x + 80,
          y + cos(i + x * 0.011) * 18,
        );
      }
      canvas.drawPath(path, smokePaint);
    }

    final texturePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;
    const spacing = 18.0;
    for (var y = 0.0; y < size.height; y += spacing) {
      for (var x = 0.0; x < size.width; x += spacing) {
        final jitter = sin(x * 12.9898 + y * 78.233);
        canvas.drawCircle(
            Offset(x, y), jitter > 0.35 ? 0.9 : 0.35, texturePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PosterGarnishLayer extends StatelessWidget {
  const _PosterGarnishLayer();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          left: 28,
          top: 118,
          child: _TomatoSlice(size: 78, angle: -0.45),
        ),
        Positioned(
          left: 172,
          top: 236,
          child: _LeafAccent(size: 48, angle: 0.25),
        ),
        Positioned(
          right: 94,
          top: 74,
          child: _LeafAccent(size: 74, angle: 0.45),
        ),
        Positioned(
          left: 48,
          bottom: 118,
          child: _ChilliAccent(width: 150, angle: -0.06),
        ),
        Positioned(
          right: 74,
          bottom: 76,
          child: _ChilliAccent(width: 130, angle: -0.20),
        ),
        Positioned(
          left: 136,
          top: 58,
          child: _WavyAccent(width: 72),
        ),
        Positioned(
          right: 96,
          top: 250,
          child: _WavyAccent(width: 82),
        ),
      ],
    );
  }
}

class _TomatoSlice extends StatelessWidget {
  final double size;
  final double angle;

  const _TomatoSlice({required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _TomatoPainter()),
      ),
    );
  }
}

class _TomatoPainter extends CustomPainter {
  const _TomatoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()..color = const Color(0xFFFF6E5D),
    );
    final seedPaint = Paint()..color = const Color(0xFFFFE09A);
    for (var i = 0; i < 10; i++) {
      final angle = i * pi / 5;
      canvas.drawOval(
        Rect.fromCenter(
          center: center + Offset(cos(angle), sin(angle)) * radius * 0.42,
          width: radius * 0.16,
          height: radius * 0.08,
        ),
        seedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LeafAccent extends StatelessWidget {
  final double size;
  final double angle;

  const _LeafAccent({required this.size, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: size * 0.56,
        height: size,
        child: const CustomPaint(painter: _LeafPainter()),
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.50, 0)
      ..cubicTo(size.width * 1.10, size.height * 0.28, size.width * 0.92,
          size.height * 0.78, size.width * 0.50, size.height)
      ..cubicTo(size.width * 0.08, size.height * 0.78, -size.width * 0.10,
          size.height * 0.28, size.width * 0.50, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF71C837));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.50, size.height * 0.10)
        ..lineTo(size.width * 0.50, size.height * 0.92),
      Paint()
        ..color = const Color(0xFFD8FF85)
        ..strokeWidth = max(1.0, size.width * 0.05)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChilliAccent extends StatelessWidget {
  final double width;
  final double angle;

  const _ChilliAccent({required this.width, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: width,
        height: width * 0.24,
        child: const CustomPaint(painter: _ChilliPainter()),
      ),
    );
  }
}

class _ChilliPainter extends CustomPainter {
  const _ChilliPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.10, size.height * 0.55)
      ..cubicTo(size.width * 0.36, size.height * 0.12, size.width * 0.73,
          size.height * 0.14, size.width * 0.93, size.height * 0.48)
      ..cubicTo(size.width * 0.72, size.height * 0.70, size.width * 0.34,
          size.height * 0.86, size.width * 0.10, size.height * 0.55)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE52420));
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.90, size.height * 0.48)
        ..quadraticBezierTo(size.width, size.height * 0.22, size.width * 1.05,
            size.height * 0.06),
      Paint()
        ..color = const Color(0xFF7FAF25)
        ..strokeWidth = size.height * 0.12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavyAccent extends StatelessWidget {
  final double width;

  const _WavyAccent({required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 16,
      child: const CustomPaint(painter: _WavyPainter()),
    );
  }
}

class _WavyPainter extends CustomPainter {
  const _WavyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height / 2);
    final segment = size.width / 8;
    for (var i = 0; i < 8; i++) {
      final x = i * segment;
      path.quadraticBezierTo(
        x + segment / 2,
        i.isEven ? 0 : size.height,
        x + segment,
        size.height / 2,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFF8A3D)
        ..strokeWidth = 2.3
        ..style = PaintingStyle.stroke,
    );
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
  final String displayLanguage;
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
    required this.displayLanguage,
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
                  displayLanguage: displayLanguage,
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
        ((size.width * 0.040) * headingFontScale).clamp(34.0, 78.0);
    final headingHeight = headingFontSize * 1.42;
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
  final String displayLanguage;
  final TvMenuThemeData theme;
  final CategoryTheme catTheme;
  final bool showDietTags;
  final double fontScale;
  final double screenWidth;
  final double height;

  const _StandardSectionHeading({
    required this.text,
    required this.sectionMode,
    required this.displayLanguage,
    required this.theme,
    required this.catTheme,
    required this.showDietTags,
    required this.fontScale,
    required this.screenWidth,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isMalayalam = _isMalayalam(displayLanguage);
    final headingText = isMalayalam ? text : text.toUpperCase();
    final fontSize = isMalayalam
        ? ((screenWidth * 0.052) * fontScale).clamp(46.0, 104.0)
        : ((screenWidth * 0.040) * fontScale).clamp(34.0, 78.0);
    final fillColor = theme.primaryText;
    final shadowColor = const Color(0xFF5A2A12).withValues(alpha: 0.46);
    final glowColor = catTheme.primary.withValues(alpha: 0.30);
    final baseStyle = isMalayalam
        ? GoogleFonts.balooChettan2(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 0.78,
            letterSpacing: -0.2,
          )
        : GoogleFonts.lilitaOne(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 0.88,
            letterSpacing: 0.6,
          );

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
                Transform.scale(
                  scaleX: isMalayalam ? 1.08 : 1,
                  scaleY: isMalayalam ? 1.16 : 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: fontSize * 0.050,
                        top: fontSize * 0.080,
                        child: Text(
                          headingText,
                          textAlign: TextAlign.center,
                          style: baseStyle.copyWith(
                            color: shadowColor,
                            shadows: [
                              Shadow(
                                color: glowColor,
                                blurRadius: fontSize * 0.34,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      Text(
                        headingText,
                        textAlign: TextAlign.center,
                        style: baseStyle.copyWith(
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth =
                                (fontSize * (isMalayalam ? 0.055 : 0.035))
                                    .clamp(1.8, 5.2)
                            ..color = catTheme.primary.withValues(alpha: 0.42),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                      Text(
                        headingText,
                        textAlign: TextAlign.center,
                        style: baseStyle.copyWith(
                          color: fillColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              offset: Offset(
                                fontSize * 0.018,
                                fontSize * 0.026,
                              ),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
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
  final String displayLanguage;
  const _EmptyState({
    required this.catTheme,
    required this.theme,
    required this.displayLanguage,
  });

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
            _localizedMenuText(displayLanguage, 'addItems'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _localizedMenuText(displayLanguage, 'newProducts'),
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
                    transform: theme.animated
                        ? GradientRotation(controller.value * 6.28318)
                        : null,
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
    final center = Alignment(
      0.36 * sin(progress * 6.28318),
      0.28 * cos(progress * 6.28318),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: center,
          radius: 1.55,
          colors: [
            theme.glowColor,
            Color.lerp(
              theme.background,
              catTheme.gradient[0],
              theme.isDark ? 0.12 : 0.08,
            )!,
            theme.background.withValues(alpha: theme.isDark ? 0.72 : 0.62),
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
