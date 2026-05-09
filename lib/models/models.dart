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
  final bool showPrice;
  final bool showDescription;
  final bool showLogo;
  final bool showCompanyName;
  final bool showProductImage;
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
    this.showPrice = true,
    this.showDescription = true,
    this.showLogo = true,
    this.showCompanyName = true,
    this.showProductImage = true,
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
      showPrice: json['showPrice'] as bool? ?? true,
      showDescription: json['showDescription'] as bool? ?? true,
      showLogo: json['showLogo'] as bool? ?? true,
      showCompanyName: json['showCompanyName'] as bool? ?? true,
      showProductImage: json['showProductImage'] as bool? ?? true,
      mediaItems: (json['mediaItems'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DisplayMediaItem.fromJson)
          .toList(),
      menuItems: (json['menuItems'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MenuItem.fromJson)
          .toList(),
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
        'showPrice': showPrice,
        'showDescription': showDescription,
        'showLogo': showLogo,
        'showCompanyName': showCompanyName,
        'showProductImage': showProductImage,
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
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      priceVariants: (json['priceVariants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PriceVariant.fromJson)
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      category: MenuCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MenuCategory.all,
      ),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
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
