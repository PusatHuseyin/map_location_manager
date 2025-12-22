import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  // Konum izinlerini kontrol et ve iste
  Future<bool> checkAndRequestPermissions() async {
    // Check if location services enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions permanently denied, open settings
      await openAppSettings();
      return false;
    }

    return true;
  }

  // Guncel konumu al
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      _lastPosition = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  // Canli konum takibini baslat
  Future<bool> startLocationTracking() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return false;

      // Stop existing stream if any
      await stopLocationTracking();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Minimum 5 metre hareket
        timeLimit: Duration(seconds: 5),
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastPosition = position;
          _positionController.add(position);
        },
        onError: (error) {
          // Handle error silently
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Canli konum takibini durdur
  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // Iki nokta arasindaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Birden fazla nokta arasindaki toplam mesafeyi hesapla
  double calculateTotalDistance(List<Position> positions) {
    if (positions.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < positions.length - 1; i++) {
      totalDistance += calculateDistance(
        positions[i].latitude,
        positions[i].longitude,
        positions[i + 1].latitude,
        positions[i + 1].longitude,
      );
    }

    return totalDistance;
  }

  // Service temizleme
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionController.close();
  }
}
