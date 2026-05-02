# MenuBoard TV — Flutter App

Premium digital menu board for restaurants. Designed for TVs, display screens, and any Android/Fire TV device. Netflix-quality dark aesthetic with a live friendly mascot.

---

## File Structure

```
lib/
├── main.dart                          # Entry point
├── theme/
│   └── app_theme.dart                 # Colors, fonts, category themes
├── models/
│   └── models.dart                    # DeviceConfig, MenuItem, DisplayConfig, enums
├── services/
│   └── device_service.dart            # Polling, pairing state, deviceCode
├── utils/
│   └── orientation_helper.dart        # Responsive layout + orientation mapping
├── screens/
│   ├── splash_screen.dart             # Boot animation
│   ├── root_screen.dart               # Routes between QR / media / menu board
│   ├── qr_pairing_screen.dart         # QR code + pairing UI
│   ├── menu_board_screen.dart         # Main menu grid display
│   └── media_screen.dart              # Full-screen image/video
└── widgets/
    ├── qr_code_widget.dart            # Styled QR code box
    ├── mascot_widget.dart             # Animated running character
    ├── menu_header_widget.dart        # Business name + live clock + category
    ├── menu_item_card.dart            # Individual item card (category-aware)
    └── ticker_bar_widget.dart         # Scrolling promo ticker
```

---

## Quick Start

### 1. Clone & install
```bash
flutter pub get
```

### 2. Add fonts
Download from Google Fonts and place in `assets/fonts/`:
- **Playfair Display** — Regular, SemiBold, Bold
- **Nunito** — Regular, Medium, SemiBold, Bold, ExtraBold, Black

### 3. Connect your backend

In `lib/services/device_service.dart`, replace:
```dart
static const String _baseUrl = 'https://api.yourdomain.com';
```
And implement the `_fetchConfig()` HTTP call (the mock is clearly labeled).

### 4. Run
```bash
flutter run -d <your-tv-device-id>
```

---

## How It Works

### Device Code (deviceCode)
- Generated once on first launch, persisted via `shared_preferences`
- **Unique per device** — matches your Prisma model: `deviceCode String @unique`
- Encoded into the QR displayed on the pairing screen

### QR Pairing Flow
1. TV shows QR → encodes `{ deviceCode, app: "menuboard", version: 1 }`
2. Mobile app scans → registers device against business in your backend
3. `isPaired: true` returned on next poll → TV transitions to menu board

### Display Modes (set from mobile app)
| Mode | What TV shows |
|------|--------------|
| `qrPairing` | QR screen (auto if not paired) |
| `media` | Full-screen image or video |
| `menuBoard` | Auto-generated menu grid |

### Menu Categories & Their Designs
| Category | Colors | Icon |
|----------|--------|------|
| `veg` | Emerald green | 🌿 |
| `nonVeg` | Warm red | 🍖 |
| `todaysStar` | Amber/gold | ⭐ |
| `beverages` | Sky blue | 🥤 |
| `desserts` | Rose pink | 🍰 |

### Orientation
Set `orientation` field in `DeviceConfig` from your mobile app:
- `landscape` — normal TV mount
- `portrait` — vertical display / digital standee
- `rotatedLeft` / `rotatedRight` — sideways mount
- `inverted` — upside-down mount

The app automatically applies the correct system orientation.

### Auto-Scroll
Items auto-scroll every N seconds (set `autoScrollIntervalSeconds` from mobile app, default 8s).

### Mascot
- Fully custom-painted golden orb character
- Runs left↔right across bottom of every screen
- Blinks, trails sparkle particles, jumps at edges
- No external assets needed — pure Flutter `CustomPainter`

---

## Backend API Contract

### GET `/api/tv-devices/:deviceCode/config`
Returns:
```json
{
  "deviceCode": "ABC123XYZ789",
  "isPaired": true,
  "businessName": "Spice Garden",
  "businessLogoUrl": "https://...",
  "orientation": "landscape",
  "displayConfig": {
    "mode": "menuBoard",
    "menuCategory": "veg",
    "autoScrollIntervalSeconds": 8
  }
}
```

### Menu Items API
Add a `GET /api/tv-devices/:deviceCode/menu-items?category=veg` endpoint.
Update `_loadItems()` in `menu_board_screen.dart` to call it.

---

## Dependencies
```yaml
qr_flutter: ^4.1.0          # QR generation
shared_preferences: ^2.2.2  # Device code persistence
http: ^1.2.0                 # Backend polling
cached_network_image: ^3.3.1 # Item images
```

Optional:
```yaml
video_player: ^2.8.2        # Video media mode
lottie: ^3.0.0              # Lottie mascot animations
```

---

## TV Platform Notes

### Android TV / Fire TV
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-feature android:name="android.software.leanback" android:required="false"/>
<uses-feature android:name="android.hardware.touchscreen" android:required="false"/>
```

### Raspberry Pi (Linux)
```bash
flutter run -d linux --release
```

### Web (for browser-based display boards)
```bash
flutter build web --release
```
