import 'dart:async';
import 'package:flutter/foundation.dart';
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

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }

    return true;
  }

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

  Future<bool> startLocationTracking() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('❌ LocationService: İzin yok!');
        return false;
      }

      await stopLocationTracking();
      debugPrint('🔵 LocationService: Position stream başlatılıyor...');

      // Platforma ozel gelismis ayarlar
      late LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 3), // 3 saniyede bir zorla
          // Arka plan icin onemli
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: "Konum takibi devam ediyor",
            notificationTitle: "Rota Kaydı Aktif",
            enableWakeLock: true,
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        );
      }

      // StreamController zaten constructor'da/field'da initialize edildi

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              debugPrint(
                '🟢 LocationService: Pozisyon alındı - (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}) accuracy=${position.accuracy}m',
              );
              _lastPosition = position;
              _positionController.add(position);
            },
            onError: (error) {
              debugPrint('🔴 LocationService: Stream hatası - $error');
            },
            onDone: () {
              debugPrint('⚪ LocationService: Stream tamamlandı');
            },
            cancelOnError: false,
          );

      debugPrint('✅ LocationService: Position stream başlatıldı');
      return true;
    } catch (e) {
      debugPrint('❌ LocationService: Hata - $e');
      return false;
    }
  }

  Future<void> stopLocationTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    debugPrint('🔴 LocationService: Tracking durduruldu (Stream açık kaldı)');
  }

  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // birden fazla nokta arasindaki toplam mesafeyi hesapla

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

  // service temizleme
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionController.close();
  }
}
