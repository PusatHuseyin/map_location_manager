import 'package:google_maps_flutter/google_maps_flutter.dart';

class AppConstants {
  // Konya coordinates (baslangic noktasi)
  static const double konyaLatitude = 37.8746;
  static const double konyaLongitude = 32.4932;
  static const LatLng konyaLocation = LatLng(konyaLatitude, konyaLongitude);

  // Map settings
  static const double defaultZoom = 13.0;
  static const double markerZoom = 15.0;
  static const double routeZoom = 14.0;

  // Location tracking settings
  static const int locationUpdateInterval = 5; // seconds
  static const double minimumDistance = 5.0; // meters

  // Database
  static const String databaseName = 'map_location_manager.db';
  static const int databaseVersion = 1;

  // UI Constants
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;
  static const double fabSize = 56.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
}
