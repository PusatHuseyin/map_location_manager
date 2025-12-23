import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/route_model.dart';
import '../models/route_point_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class RouteProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  RouteModel? _activeRoute;
  List<RoutePointModel> _currentRoutePoints = [];
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;
  int _elapsedSeconds = 0;

  RouteModel? get activeRoute => _activeRoute;
  List<RoutePointModel> get currentRoutePoints => _currentRoutePoints;
  bool get isTracking => _activeRoute != null && _activeRoute!.isActive;
  int get elapsedSeconds => _elapsedSeconds;

  String get formattedDuration {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  RouteProvider() {
    _checkForActiveRoute();
  }

  Future<void> _checkForActiveRoute() async {
    try {
      _activeRoute = await _databaseService.getActiveRoute();
      if (_activeRoute != null) {
        _currentRoutePoints = _activeRoute!.points;

        if (_activeRoute!.isActive) {
          _elapsedSeconds = DateTime.now()
              .difference(_activeRoute!.startTime)
              .inSeconds;
        }
        notifyListeners();
      }
    } catch (e) {}
  }

  Future<bool> startRouteTracking() async {
    try {
      final hasPermission = await _locationService.checkAndRequestPermissions();
      if (!hasPermission) {
        debugPrint('❌ RouteProvider: Konum izni alinamadi');
        return false;
      }

      final routeId = _uuid.v4();
      _activeRoute = RouteModel(
        id: routeId,
        name:
            'Rota ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}',
        startTime: DateTime.now(),
      );

      await _databaseService.insertRoute(_activeRoute!);
      _currentRoutePoints = [];
      _elapsedSeconds = 0;

      debugPrint('✅ RouteProvider: Rota baslatildi - ID: ${_activeRoute!.id}');

      // Ilk pozisyonu hemen al ve kaydet
      final initialPosition = await _locationService.getCurrentPosition();
      if (initialPosition != null) {
        debugPrint('📍 Baslangic pozisyonu alindi');
        _addRoutePoint(initialPosition);
      } else {
        debugPrint('❌ Baslangic pozisyonu alinamadi!');
      }

      // ÖNCE stream'e subscribe ol, SONRA tracking'i başlat
      debugPrint('🔵 RouteProvider: Stream listener oluşturuluyor...');

      // Stream subscription oluştur
      _positionSubscription = _locationService.positionStream.listen(
        (position) {
          debugPrint(
            '📍 GPS Stream: (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}) accuracy=${position.accuracy.toStringAsFixed(1)}m',
          );
          _addRoutePoint(position);
        },
        onError: (error) {
          debugPrint('❌ GPS Stream Hatasi: $error');
        },
        onDone: () {
          debugPrint('⚠️ GPS Stream kapandi');
        },
        cancelOnError: false,
      );

      debugPrint('✅ RouteProvider: Stream listener hazir');

      // Stream'i baslat (artık dinleyici hazır)
      await _locationService.startLocationTracking();
      debugPrint('✅ RouteProvider: LocationService tracking baslatildi');

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        notifyListeners();
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ RouteProvider: Hata - $e');
      return false;
    }
  }

  void _addRoutePoint(Position position) {
    if (_activeRoute == null) {
      debugPrint('⚠️ addRoutePoint: activeRoute null!');
      return;
    }

    final point = RoutePointModel(
      id: _uuid.v4(),
      routeId: _activeRoute!.id,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed,
      accuracy: position.accuracy,
    );

    _currentRoutePoints.add(point);
    _databaseService.insertRoutePoint(point);
    debugPrint(
      '💾 Nokta kaydedildi: Toplam ${_currentRoutePoints.length} nokta, Mesafe: $formattedCurrentDistance',
    );
    notifyListeners();
  }

  Future<bool> stopRouteTracking({String? customName}) async {
    if (_activeRoute == null) return false;

    try {
      await _locationService.stopLocationTracking();
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _durationTimer?.cancel();
      _durationTimer = null;

      double totalDistance = 0.0;
      if (_currentRoutePoints.length >= 2) {
        for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
          totalDistance += _locationService.calculateDistance(
            _currentRoutePoints[i].latitude,
            _currentRoutePoints[i].longitude,
            _currentRoutePoints[i + 1].latitude,
            _currentRoutePoints[i + 1].longitude,
          );
        }
      }

      final updatedRoute = _activeRoute!.copyWith(
        name: customName ?? _activeRoute!.name,
        endTime: DateTime.now(),
        totalDistance: totalDistance,
        duration: _elapsedSeconds,
        points: _currentRoutePoints,
      );

      await _databaseService.updateRoute(updatedRoute);

      _activeRoute = null;
      _currentRoutePoints = [];
      _elapsedSeconds = 0;

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  double get currentDistance {
    if (_currentRoutePoints.length < 2) return 0.0;

    double distance = 0.0;
    for (int i = 0; i < _currentRoutePoints.length - 1; i++) {
      distance += _locationService.calculateDistance(
        _currentRoutePoints[i].latitude,
        _currentRoutePoints[i].longitude,
        _currentRoutePoints[i + 1].latitude,
        _currentRoutePoints[i + 1].longitude,
      );
    }
    return distance;
  }

  String get formattedCurrentDistance {
    if (currentDistance > 999) {
      return '${(currentDistance / 1000).toStringAsFixed(2)} km';
    }
    return '${currentDistance.toStringAsFixed(0)} m';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
