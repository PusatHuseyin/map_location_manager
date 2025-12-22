import 'package:flutter/foundation.dart';
import '../models/route_model.dart';
import '../services/database_service.dart';

class RoutesProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<RouteModel> _routes = [];
  RouteModel? _selectedRoute;
  bool _isLoading = false;
  String? _error;

  List<RouteModel> get routes => _routes;
  RouteModel? get selectedRoute => _selectedRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  RoutesProvider() {
    loadRoutes();
  }

  // Tum rotalari yukle
  Future<void> loadRoutes() async {
    _setLoading(true);
    try {
      _routes = await _databaseService.getAllRoutes();
      // Sadece tamamlanmis rotalari getir
      _routes = _routes.where((route) => !route.isActive).toList();
      _error = null;
    } catch (e) {
      _error = 'Rotalar yuklenirken hata olustu';
    } finally {
      _setLoading(false);
    }
  }

  // Rota sec
  void selectRoute(RouteModel? route) {
    _selectedRoute = route;
    notifyListeners();
  }

  // Rota sil
  Future<bool> deleteRoute(String id) async {
    try {
      await _databaseService.deleteRoute(id);
      await loadRoutes();
      if (_selectedRoute?.id == id) {
        _selectedRoute = null;
      }
      return true;
    } catch (e) {
      _error = 'Rota silinirken hata olustu';
      notifyListeners();
      return false;
    }
  }

  // Rotayi ID ile getir
  Future<RouteModel?> getRouteById(String id) async {
    try {
      return await _databaseService.getRoute(id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
