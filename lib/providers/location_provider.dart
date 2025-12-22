import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/location_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  final Uuid _uuid = const Uuid();

  List<LocationModel> _locations = [];
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  List<LocationModel> get locations => _locations;
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocationPermission => _currentPosition != null;

  LocationProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadLocations();
    await updateCurrentPosition();
    _startLocationTracking();
  }

  // Tum konumlari yukle
  Future<void> loadLocations() async {
    _setLoading(true);
    try {
      _locations = await _databaseService.getAllLocations();
      _error = null;
    } catch (e) {
      _error = 'Konumlar yuklenirken hata olustu';
    } finally {
      _setLoading(false);
    }
  }

  // Yeni konum ekle
  Future<bool> addLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    try {
      final location = LocationModel(
        id: _uuid.v4(),
        name: name,
        latitude: latitude,
        longitude: longitude,
        description: description,
        createdAt: DateTime.now(),
      );

      await _databaseService.insertLocation(location);
      await loadLocations();
      return true;
    } catch (e) {
      _error = 'Konum eklenirken hata olustu';
      notifyListeners();
      return false;
    }
  }

  // Konum sil
  Future<bool> deleteLocation(String id) async {
    try {
      await _databaseService.deleteLocation(id);
      await loadLocations();
      return true;
    } catch (e) {
      _error = 'Konum silinirken hata olustu';
      notifyListeners();
      return false;
    }
  }

  // Mevcut konumu guncelle
  Future<void> updateCurrentPosition() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
        _error = null;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Konum alinamadi';
      notifyListeners();
    }
  }

  // Canli konum takibini baslat
  void _startLocationTracking() {
    _locationService.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  // Izin kontrolu yap
  Future<bool> checkPermissions() async {
    final hasPermission = await _locationService.checkAndRequestPermissions();
    if (hasPermission) {
      await updateCurrentPosition();
    } else {
      _error = 'Konum izni reddedildi';
      notifyListeners();
    }
    return hasPermission;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }
}
