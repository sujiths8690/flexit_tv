// lib/models/models.dart

import '../theme/app_theme.dart';

enum DisplayMode { qrPairing, media, menuBoard }

enum MenuCategory { veg, nonVeg, todaysStar, beverages, desserts, all }

enum DisplayOrientation {
  normal,
  left,
  right,
  inverted,
  landscape,
  portrait,
  rotatedLeft,
  rotatedRight,
}

class DeviceConfig {
  final String deviceCode; // Unique device identifier (UUID)
  final bool isPaired;
  final String? businessName;
  final String? businessLogoUrl;
  final DisplayOrientation orientation;
  final DisplayConfig? displayConfig;
  final MenuThemeType? menuTheme;
  final String themeColor;

  const DeviceConfig({
    required this.deviceCode,
    required this.isPaired,
    this.businessName,
    this.businessLogoUrl,
    this.orientation = DisplayOrientation.normal,
    this.displayConfig,
    this.menuTheme,
    this.themeColor = 'gold',
  });

  DeviceConfig copyWith({
    bool? isPaired,
    String? businessName,
    String? businessLogoUrl,
    DisplayOrientation? orientation,
    DisplayConfig? displayConfig,
    MenuThemeType? menuTheme,
    String? themeColor,
  }) {
    return DeviceConfig(
      deviceCode: deviceCode,
      isPaired: isPaired ?? this.isPaired,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      orientation: orientation ?? this.orientation,
      displayConfig: displayConfig ?? this.displayConfig,
      menuTheme: menuTheme ?? this.menuTheme,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    final menuThemeName = json['menuTheme'] as String?;
    return DeviceConfig(
      deviceCode: json['deviceCode'] as String,
      isPaired: json['isPaired'] as bool,
      businessName: json['businessName'] as String?,
      businessLogoUrl: json['businessLogoUrl'] as String?,
      orientation: _parseOrientation(json['orientation'] as String?),
      displayConfig: json['displayConfig'] != null
          ? DisplayConfig.fromJson(
              json['displayConfig'] as Map<String, dynamic>)
          : null,
      menuTheme: menuThemeName != null
          ? MenuThemeType.values.firstWhere(
              (e) => e.name == menuThemeName,
              orElse: () => MenuThemeType.light,
            )
          : null,
      themeColor: json['themeColor'] as String? ?? 'gold',
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceCode': deviceCode,
        'isPaired': isPaired,
        'businessName': businessName,
        'businessLogoUrl': businessLogoUrl,
        'orientation': orientation.name,
        'displayConfig': displayConfig?.toJson(),
        'menuTheme': menuTheme?.name,
        'themeColor': themeColor,
      };
}

DisplayOrientation _parseOrientation(String? value) {
  switch (value) {
    case 'normal':
    case 'landscape':
      return DisplayOrientation.normal;
    case 'left':
    case 'rotatedLeft':
      return DisplayOrientation.left;
    case 'right':
    case 'rotatedRight':
      return DisplayOrientation.right;
    case 'inverted':
      return DisplayOrientation.inverted;
    case 'portrait':
      return DisplayOrientation.normal;
    default:
      return DisplayOrientation.normal;
  }
}

class DisplayConfig {
  final DisplayMode mode;
  final String? mediaUrl; // if mode == media
  final String? mediaType; // 'image' | 'video'
  final MenuCategory? menuCategory; // if mode == menuBoard
  final String contentMode;
  final int? selectedCategoryId;
  final int? selectedMediaId;
  final String? themeOverride;
  final String? themeColor;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final int? autoScrollIntervalSeconds;
  final bool scheduleEnabled;
  final bool alwaysOn;
  final String scheduleStartTime;
  final String scheduleEndTime;
  final bool showPrice;
  final bool showDescription;
  final bool showLogo;
  final bool showCompanyName;
  final bool showProductImage;
  final bool showDietTags;
  final double headingFontScale;
  final double nameFontScale;
  final double descriptionFontScale;
  final double priceFontScale;
  final List<DisplayMediaItem> mediaItems;
  final List<MenuItem> menuItems;

  const DisplayConfig({
    required this.mode,
    this.mediaUrl,
    this.mediaType,
    this.menuCategory,
    this.contentMode = 'allCategories',
    this.selectedCategoryId,
    this.selectedMediaId,
    this.themeOverride,
    this.themeColor,
    this.transitionStyle = 'fade',
    this.transitionSpeedSeconds = 0.5,
    this.autoScrollIntervalSeconds,
    this.scheduleEnabled = false,
    this.alwaysOn = true,
    this.scheduleStartTime = '09:00',
    this.scheduleEndTime = '22:00',
    this.showPrice = true,
    this.showDescription = true,
    this.showLogo = true,
    this.showCompanyName = true,
    this.showProductImage = true,
    this.showDietTags = true,
    this.headingFontScale = 1.0,
    this.nameFontScale = 1.0,
    this.descriptionFontScale = 1.0,
    this.priceFontScale = 1.0,
    this.mediaItems = const [],
    this.menuItems = const [],
  });

  factory DisplayConfig.fromJson(Map<String, dynamic> json) {
    return DisplayConfig(
      mode: DisplayMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => DisplayMode.menuBoard,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      contentMode: json['contentMode'] as String? ?? 'allCategories',
      selectedCategoryId: (json['selectedCategoryId'] as num?)?.toInt(),
      selectedMediaId: (json['selectedMediaId'] as num?)?.toInt(),
      menuCategory: json['menuCategory'] != null
          ? MenuCategory.values.firstWhere(
              (e) => e.name == json['menuCategory'],
              orElse: () => MenuCategory.all,
            )
          : null,
      themeOverride: json['themeOverride'] as String?,
      themeColor: json['themeColor'] as String?,
      transitionStyle: json['transitionStyle'] as String? ?? 'fade',
      transitionSpeedSeconds:
          (json['transitionSpeedSeconds'] as num?)?.toDouble() ?? 0.5,
      autoScrollIntervalSeconds: json['autoScrollIntervalSeconds'] as int?,
      scheduleEnabled: json['scheduleEnabled'] as bool? ?? false,
      alwaysOn: json['alwaysOn'] as bool? ?? true,
      scheduleStartTime: json['scheduleStartTime'] as String? ?? '09:00',
      scheduleEndTime: json['scheduleEndTime'] as String? ?? '22:00',
      showPrice: json['showPrice'] as bool? ?? true,
      showDescription: json['showDescription'] as bool? ?? true,
      showLogo: json['showLogo'] as bool? ?? true,
      showCompanyName: json['showCompanyName'] as bool? ?? true,
      showProductImage: json['showProductImage'] as bool? ?? true,
      showDietTags: json['showDietTags'] as bool? ?? true,
      headingFontScale: (json['headingFontScale'] as num?)?.toDouble() ?? 1.0,
      nameFontScale: (json['nameFontScale'] as num?)?.toDouble() ?? 1.0,
      descriptionFontScale:
          (json['descriptionFontScale'] as num?)?.toDouble() ?? 1.0,
      priceFontScale: (json['priceFontScale'] as num?)?.toDouble() ?? 1.0,
      mediaItems: (json['mediaItems'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DisplayMediaItem.fromJson)
          .toList(),
      menuItems: _parseMenuItems(json['menuItems'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'menuCategory': menuCategory?.name,
        'contentMode': contentMode,
        'selectedCategoryId': selectedCategoryId,
        'selectedMediaId': selectedMediaId,
        'themeOverride': themeOverride,
        'themeColor': themeColor,
        'transitionStyle': transitionStyle,
        'transitionSpeedSeconds': transitionSpeedSeconds,
        'autoScrollIntervalSeconds': autoScrollIntervalSeconds,
        'scheduleEnabled': scheduleEnabled,
        'alwaysOn': alwaysOn,
        'scheduleStartTime': scheduleStartTime,
        'scheduleEndTime': scheduleEndTime,
        'showPrice': showPrice,
        'showDescription': showDescription,
        'showLogo': showLogo,
        'showCompanyName': showCompanyName,
        'showProductImage': showProductImage,
        'showDietTags': showDietTags,
        'headingFontScale': headingFontScale,
        'nameFontScale': nameFontScale,
        'descriptionFontScale': descriptionFontScale,
        'priceFontScale': priceFontScale,
        'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
        'menuItems': menuItems.map((item) => item.toJson()).toList(),
      };
}

class DisplayMediaItem {
  final int id;
  final String fileName;
  final String url;
  final String type;

  const DisplayMediaItem({
    required this.id,
    required this.fileName,
    required this.url,
    required this.type,
  });

  factory DisplayMediaItem.fromJson(Map<String, dynamic> json) {
    return DisplayMediaItem(
      id: (json['id'] as num).toInt(),
      fileName: json['fileName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: (json['type'] as String? ?? 'image').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'url': url,
        'type': type,
      };
}

List<MenuItem> _parseMenuItems(List<dynamic> items) {
  final parsed = <MenuItem>[];
  for (final item in items.whereType<Map<String, dynamic>>()) {
    try {
      parsed.add(MenuItem.fromJson(item));
    } catch (_) {
      // Skip malformed menu/combo items so one bad payload does not unpair TV.
    }
  }
  return parsed;
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final List<PriceVariant> priceVariants;
  final String? imageUrl;
  final MenuCategory category;
  final int? categoryId;
  final String? categoryName;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> tags;
  final double? originalPrice; // for strike-through discount display
  final List<ComboOfferItem> comboItems;

  const MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.priceVariants = const [],
    this.imageUrl,
    required this.category,
    this.categoryId,
    this.categoryName,
    this.isAvailable = true,
    this.isFeatured = false,
    this.tags = const [],
    this.originalPrice,
    this.comboItems = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      priceVariants: (json['priceVariants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PriceVariant.fromJson)
          .toList(),
      imageUrl: _parseImageUrl(json['imageUrl'] as String?),
      category: MenuCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MenuCategory.all,
      ),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      originalPrice: (json['originalPrice'] ??
                  json['actualPrice'] ??
                  json['totalActualPrice']) !=
              null
          ? ((json['originalPrice'] ??
                  json['actualPrice'] ??
                  json['totalActualPrice']) as num)
              .toDouble()
          : null,
      comboItems: _parseComboOfferItems(
        (json['comboItems'] ?? json['items']) as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'priceVariants':
            priceVariants.map((variant) => variant.toJson()).toList(),
        'imageUrl': imageUrl,
        'category': category.name,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'isAvailable': isAvailable,
        'isFeatured': isFeatured,
        'tags': tags,
        'originalPrice': originalPrice,
        'comboItems': comboItems.map((item) => item.toJson()).toList(),
      };
}

String? _parseImageUrl(String? url) {
  final value = url?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('http')) return value;
  final path = value.startsWith('/') ? value.substring(1) : value;
  return 'http://192.168.29.184:4002/$path';
}

List<ComboOfferItem> _parseComboOfferItems(List<dynamic> items) {
  final parsed = <ComboOfferItem>[];
  for (final item in items.whereType<Map<String, dynamic>>()) {
    try {
      parsed.add(ComboOfferItem.fromJson(item));
    } catch (_) {
      // Ignore malformed combo children instead of failing the whole display.
    }
  }
  return parsed;
}

class ComboOfferItem {
  final int id;
  final int quantity;
  final String? variantLabel;
  final double? variantPrice;
  final MenuItem product;

  const ComboOfferItem({
    required this.id,
    required this.quantity,
    this.variantLabel,
    this.variantPrice,
    required this.product,
  });

  factory ComboOfferItem.fromJson(Map<String, dynamic> json) {
    final productJson =
        (json['product'] ?? json['menuItem']) as Map<String, dynamic>;
    return ComboOfferItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantLabel: json['variantLabel'] as String?,
      variantPrice: (json['variantPrice'] as num?)?.toDouble(),
      product: MenuItem.fromJson(productJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quantity': quantity,
        'variantLabel': variantLabel,
        'variantPrice': variantPrice,
        'product': product.toJson(),
      };
}

class PriceVariant {
  final String label;
  final double price;

  const PriceVariant({
    required this.label,
    required this.price,
  });

  factory PriceVariant.fromJson(Map<String, dynamic> json) {
    return PriceVariant(
      label: json['label'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'price': price,
      };
}

// Mock data for demonstration
class MockData {
  static List<MenuItem> get sampleMenuItems => [
        MenuItem(
          id: '1',
          name: 'Paneer Tikka',
          description: 'Marinated cottage cheese grilled to perfection',
          price: 280,
          category: MenuCategory.veg,
          isFeatured: true,
          tags: ['spicy', 'grilled'],
          imageUrl:
              'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400',
        ),
        MenuItem(
          id: '2',
          name: 'Dal Makhani',
          description: 'Slow-cooked black lentils in rich tomato gravy',
          price: 220,
          category: MenuCategory.veg,
          tags: ['rich', 'creamy'],
          imageUrl:
              'https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=400',
        ),
        MenuItem(
          id: '3',
          name: 'Veg Biryani',
          description: 'Fragrant basmati rice with garden vegetables',
          price: 260,
          category: MenuCategory.veg,
          tags: ['rice', 'aromatic'],
          imageUrl:
              'https://images.unsplash.com/photo-1563379091339-03246963d96c?w=400',
        ),
        MenuItem(
          id: '4',
          name: 'Chicken Tikka Masala',
          description: 'Tender chicken in creamy spiced tomato sauce',
          price: 340,
          category: MenuCategory.nonVeg,
          isFeatured: true,
          tags: ['chicken', 'creamy'],
          imageUrl:
              'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400',
        ),
        MenuItem(
          id: '5',
          name: 'Mutton Rogan Josh',
          description: 'Kashmiri style slow-cooked mutton',
          price: 420,
          category: MenuCategory.nonVeg,
          tags: ['mutton', 'kashmiri'],
          imageUrl:
              'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=400',
        ),
        MenuItem(
          id: '6',
          name: 'Butter Chicken',
          description: 'Iconic creamy tomato-based chicken curry',
          price: 320,
          category: MenuCategory.nonVeg,
          originalPrice: 380,
          tags: ['chicken', 'butter'],
          imageUrl:
              'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400',
        ),
        MenuItem(
          id: '7',
          name: 'Special Thali',
          description: "Chef's curated selection of the day's finest",
          price: 450,
          category: MenuCategory.todaysStar,
          isFeatured: true,
          tags: ['special', 'curated'],
          imageUrl:
              'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400',
        ),
        MenuItem(
          id: '8',
          name: 'Saffron Kheer',
          description: 'Traditional rice pudding with saffron',
          price: 150,
          category: MenuCategory.desserts,
          imageUrl:
              'https://images.unsplash.com/photo-1567337710282-00832b415979?w=400',
        ),
        MenuItem(
          id: '9',
          name: 'Fresh Lime Soda',
          description: 'Zesty and refreshing house special',
          price: 80,
          category: MenuCategory.beverages,
          imageUrl:
              'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400',
        ),
      ];
}
