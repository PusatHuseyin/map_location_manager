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

  // Aktif rota var mi kontrol et
  Future<void> _checkForActiveRoute() async {
    try {
      _activeRoute = await _databaseService.getActiveRoute();
      if (_activeRoute != null) {
        _currentRoutePoints = _activeRoute!.points;
        // Calculate elapsed time if route is still active
        if (_activeRoute!.isActive) {
          _elapsedSeconds = DateTime.now()
              .difference(_activeRoute!.startTime)
              .inSeconds;
        }
        notifyListeners();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Rota kaydini baslat
  Future<bool> startRouteTracking() async {
    try {
      // Konum izinlerini kontrol et
      final hasPermission = await _locationService.checkAndRequestPermissions();
      if (!hasPermission) return false;

      // Yeni rota olustur
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

      // Konum takibini baslat
      await _locationService.startLocationTracking();

      // Konum guncellemelerini dinle
      _positionSubscription = _locationService.positionStream.listen((
        position,
      ) {
        _addRoutePoint(position);
      });

      // Duration timer baslat
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        notifyListeners();
      });

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rota noktasi ekle
  void _addRoutePoint(Position position) {
    if (_activeRoute == null) return;

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
    notifyListeners();
  }

  // Stop route tracking
  Future<bool> stopRouteTracking({String? customName}) async {
    if (_activeRoute == null) return false;

    try {
      await _locationService.stopLocationTracking();
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _durationTimer?.cancel();
      _durationTimer = null;

      // Calculate total distance
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

      // Update route with custom name if provided
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

  // Hesaplanan mesafe (canli)
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
    if (currentDistance >= 1000) {
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
