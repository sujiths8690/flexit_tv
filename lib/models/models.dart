// lib/models/models.dart

enum DisplayMode { qrPairing, media, menuBoard }
enum MenuCategory { veg, nonVeg, todaysStar, beverages, desserts, all }
enum DisplayOrientation { landscape, portrait, rotatedLeft, rotatedRight, inverted }

class DeviceConfig {
  final String deviceCode;          // Unique device identifier (UUID)
  final bool isPaired;
  final String? businessName;
  final String? businessLogoUrl;
  final DisplayOrientation orientation;
  final DisplayConfig? displayConfig;

  const DeviceConfig({
    required this.deviceCode,
    required this.isPaired,
    this.businessName,
    this.businessLogoUrl,
    this.orientation = DisplayOrientation.landscape,
    this.displayConfig,
  });

  DeviceConfig copyWith({
    bool? isPaired,
    String? businessName,
    String? businessLogoUrl,
    DisplayOrientation? orientation,
    DisplayConfig? displayConfig,
  }) {
    return DeviceConfig(
      deviceCode: deviceCode,
      isPaired: isPaired ?? this.isPaired,
      businessName: businessName ?? this.businessName,
      businessLogoUrl: businessLogoUrl ?? this.businessLogoUrl,
      orientation: orientation ?? this.orientation,
      displayConfig: displayConfig ?? this.displayConfig,
    );
  }

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      deviceCode: json['deviceCode'] as String,
      isPaired: json['isPaired'] as bool,
      businessName: json['businessName'] as String?,
      businessLogoUrl: json['businessLogoUrl'] as String?,
      orientation: DisplayOrientation.values.firstWhere(
        (e) => e.name == (json['orientation'] ?? 'landscape'),
        orElse: () => DisplayOrientation.landscape,
      ),
      displayConfig: json['displayConfig'] != null
          ? DisplayConfig.fromJson(json['displayConfig'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceCode': deviceCode,
        'isPaired': isPaired,
        'businessName': businessName,
        'businessLogoUrl': businessLogoUrl,
        'orientation': orientation.name,
        'displayConfig': displayConfig?.toJson(),
      };
}

class DisplayConfig {
  final DisplayMode mode;
  final String? mediaUrl;         // if mode == media
  final String? mediaType;        // 'image' | 'video'
  final MenuCategory? menuCategory; // if mode == menuBoard
  final String? themeOverride;
  final int? autoScrollIntervalSeconds;

  const DisplayConfig({
    required this.mode,
    this.mediaUrl,
    this.mediaType,
    this.menuCategory,
    this.themeOverride,
    this.autoScrollIntervalSeconds,
  });

  factory DisplayConfig.fromJson(Map<String, dynamic> json) {
    return DisplayConfig(
      mode: DisplayMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => DisplayMode.menuBoard,
      ),
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      menuCategory: json['menuCategory'] != null
          ? MenuCategory.values.firstWhere(
              (e) => e.name == json['menuCategory'],
              orElse: () => MenuCategory.all,
            )
          : null,
      themeOverride: json['themeOverride'] as String?,
      autoScrollIntervalSeconds: json['autoScrollIntervalSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'menuCategory': menuCategory?.name,
        'themeOverride': themeOverride,
        'autoScrollIntervalSeconds': autoScrollIntervalSeconds,
      };
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final MenuCategory category;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> tags;
  final double? originalPrice; // for strike-through discount display

  const MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.category,
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
      imageUrl: json['imageUrl'] as String?,
      category: MenuCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => MenuCategory.all,
      ),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      tags: List<String>.from(json['tags'] as List? ?? []),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
    );
  }
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
          imageUrl: 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400',
        ),
        MenuItem(
          id: '2',
          name: 'Dal Makhani',
          description: 'Slow-cooked black lentils in rich tomato gravy',
          price: 220,
          category: MenuCategory.veg,
          tags: ['rich', 'creamy'],
          imageUrl: 'https://images.unsplash.com/photo-1546833998-877b37c2e5c6?w=400',
        ),
        MenuItem(
          id: '3',
          name: 'Veg Biryani',
          description: 'Fragrant basmati rice with garden vegetables',
          price: 260,
          category: MenuCategory.veg,
          tags: ['rice', 'aromatic'],
          imageUrl: 'https://images.unsplash.com/photo-1563379091339-03246963d96c?w=400',
        ),
        MenuItem(
          id: '4',
          name: 'Chicken Tikka Masala',
          description: 'Tender chicken in creamy spiced tomato sauce',
          price: 340,
          category: MenuCategory.nonVeg,
          isFeatured: true,
          tags: ['chicken', 'creamy'],
          imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=400',
        ),
        MenuItem(
          id: '5',
          name: 'Mutton Rogan Josh',
          description: 'Kashmiri style slow-cooked mutton',
          price: 420,
          category: MenuCategory.nonVeg,
          tags: ['mutton', 'kashmiri'],
          imageUrl: 'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=400',
        ),
        MenuItem(
          id: '6',
          name: 'Butter Chicken',
          description: 'Iconic creamy tomato-based chicken curry',
          price: 320,
          category: MenuCategory.nonVeg,
          originalPrice: 380,
          tags: ['chicken', 'butter'],
          imageUrl: 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=400',
        ),
        MenuItem(
          id: '7',
          name: 'Special Thali',
          description: "Chef's curated selection of the day's finest",
          price: 450,
          category: MenuCategory.todaysStar,
          isFeatured: true,
          tags: ['special', 'curated'],
          imageUrl: 'https://images.unsplash.com/photo-1606491956689-2ea866880c84?w=400',
        ),
        MenuItem(
          id: '8',
          name: 'Saffron Kheer',
          description: 'Traditional rice pudding with saffron',
          price: 150,
          category: MenuCategory.desserts,
          imageUrl: 'https://images.unsplash.com/photo-1567337710282-00832b415979?w=400',
        ),
        MenuItem(
          id: '9',
          name: 'Fresh Lime Soda',
          description: 'Zesty and refreshing house special',
          price: 80,
          category: MenuCategory.beverages,
          imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400',
        ),
      ];
}
