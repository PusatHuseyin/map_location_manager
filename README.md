# Map Location Manager

A professional Flutter application for managing locations and tracking routes with real-time GPS integration.

## Features

### Location Management
- ✅ Add locations manually or from current GPS position
- ✅ Add locations by long-pressing on map
- ✅ Edit existing locations (name, coordinates, description)
- ✅ Delete locations with confirmation
- ✅ View all locations on interactive map
- ✅ Persistent storage with SQLite

### Route Tracking
- ✅ Real-time GPS route tracking
- ✅ Start/stop route recording
- ✅ Custom route naming
- ✅ Automatic distance and duration calculation
- ✅ Route history with detailed statistics
- ✅ View routes on map with polylines
- ✅ Delete routes with confirmation

### UI/UX
- ✅ Modern Material Design 3
- ✅ Dark mode support (Light/Dark/System)
- ✅ Smooth animations and transitions
- ✅ Responsive design
- ✅ Turkish language interface
- ✅ Intuitive navigation with bottom bar

## Screenshots

*Screenshots will be added after testing on device*

## Tech Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **Permissions**: Permission Handler

## Architecture

```
lib/
├── core/
│   ├── constants/     # App constants (colors, coordinates, etc.)
│   ├── theme/         # Light and dark themes
│   └── utils/         # Utilities (strings, validators, formatters)
├── models/            # Data models (Location, Route, RoutePoint)
├── providers/         # State management (Provider pattern)
├── screens/           # UI screens
│   ├── home_screen.dart
│   ├── locations/     # Location management screens
│   ├── map/           # Map screen
│   ├── routes/        # Route screens
│   └── splash/        # Splash screen
├── services/          # Business logic
│   ├── database_service.dart
│   └── location_service.dart
├── widgets/           # Reusable widgets
└── main.dart
```

## Database Schema

### Locations Table
```sql
CREATE TABLE locations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  description TEXT,
  created_at TEXT NOT NULL
)
```

### Routes Table
```sql
CREATE TABLE routes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  total_distance REAL,
  duration INTEGER
)
```

### Route Points Table
```sql
CREATE TABLE route_points (
  id TEXT PRIMARY KEY,
  route_id TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  timestamp TEXT NOT NULL,
  speed REAL,
  accuracy REAL,
  FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE
)
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart SDK 3.9.2 or higher
- Android Studio / Xcode (for mobile development)
- Google Maps API Key

### 1. Clone Repository
```bash
git clone <repository-url>
cd map_location_manager
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Google Maps API Key Setup

#### Android
1. Get your API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Open `android/app/src/main/AndroidManifest.xml`
3. Add your API key:
```xml
<manifest ...>
  <application ...>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_API_KEY_HERE"/>
  </application>
</manifest>
```

#### iOS
1. Open `ios/Runner/AppDelegate.swift`
2. Add your API key:
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 4. Platform-Specific Setup

#### Android Permissions
Already configured in `android/app/src/main/AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` (for route tracking)

#### iOS Permissions
Already configured in `ios/Runner/Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysUsageDescription`

### 5. Run the App

#### Debug Mode
```bash
flutter run
```

#### Release Mode
```bash
flutter run --release
```

## Building for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```
Then open Xcode to archive and upload to App Store.

## Usage Guide

### Adding Locations
1. **Manual Entry**: Tap the + button on Locations screen
2. **Current Location**: Check "Use current location" in the dialog
3. **From Map**: Long-press anywhere on the map

### Tracking Routes
1. Go to Map screen
2. Tap "Başlat" button to start tracking
3. Move around - the app will record your path
4. Tap "Bitir" to stop and name your route
5. View saved routes in Routes screen

### Viewing Route Details
1. Go to Routes screen
2. Tap on any route card
3. View route on map with statistics

### Changing Theme
- Tap the theme icon (sun/moon) in the app bar
- Toggles between light and dark mode

## Testing

### Run Tests
```bash
flutter test
```

### Run with Coverage
```bash
flutter test --coverage
```

## Performance Optimization

- Efficient database queries with indexes
- Selective widget rebuilds with Provider
- Lazy loading of route points
- Optimized map marker rendering

## Known Limitations

- Requires active internet for map tiles
- GPS accuracy depends on device hardware
- Background tracking may be limited by OS power management

## Future Enhancements

- [ ] GPX export functionality
- [ ] Route search and filtering
- [ ] Analytics dashboard
- [ ] Multi-language support
- [ ] Route sharing
- [ ] Offline map caching

## License

This project is created as a technical assessment task.

## Contact

For questions or issues, please contact the developer.

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Developed with**: Flutter & ❤️