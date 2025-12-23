import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_strings.dart';
import '../../providers/location_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/routes_provider.dart';
import '../../models/location_model.dart';
import '../../models/route_model.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/add_location_from_map_dialog.dart';
import '../../core/utils/map_styles.dart';
import '../routes/route_name_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isInitialized = false;
  String? _lastFocusedLocationId;
  String? _lastFocusedRouteId;

  // Degisiklikleri takip etmek icin
  int _previousLocationCount = 0;
  int _previousRoutePointCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = context.read<LocationProvider>();

    final hasPermission = await locationProvider.checkPermissions();

    if (mounted) {
      if (hasPermission) {
        setState(() => _isInitialized = true);
        _updateMarkersAndRoute();

        locationProvider.updateCurrentPosition();
        locationProvider.startLocationTracking();
      } else {
        setState(() => _isInitialized = false);
      }
    }
  }

  void _updateMarkersAndRoute() {
    if (!mounted) return;

    final locationProvider = context.read<LocationProvider>();
    final routeProvider = context.read<RouteProvider>();

    setState(() {
      _markers.clear();
      _polylines.clear();

      for (var location in locationProvider.locations) {
        _markers.add(_createLocationMarker(location));
      }

      if (locationProvider.currentPosition != null) {
        _markers.add(_createCurrentLocationMarker(locationProvider));
      }

      if (routeProvider.isTracking &&
          routeProvider.currentRoutePoints.isNotEmpty) {
        _addActiveRoutePolylines(routeProvider);
      }
    });
  }

  Marker _createLocationMarker(LocationModel location) {
    String? distanceText;
    final locationProvider = context.read<LocationProvider>();

    if (locationProvider.currentPosition != null) {
      final distance = Geolocator.distanceBetween(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );
      distanceText = Formatters.distance(distance);
    }

    return Marker(
      markerId: MarkerId(location.id),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      infoWindow: InfoWindow(
        title: location.name,
        snippet: distanceText != null
            ? 'Uzaklık: $distanceText\n${location.description ?? ""}'
            : location.description,
      ),
    );
  }

  Marker _createCurrentLocationMarker(LocationProvider provider) {
    final position = provider.currentPosition!;
    return Marker(
      markerId: const MarkerId('current_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(title: 'Mevcut Konumum'),
    );
  }

  // Aktif rota icin Google Maps tarzi profesyonel polyline ekle
  void _addActiveRoutePolylines(RouteProvider provider) {
    final points = provider.currentRoutePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    // 1. Alt tabaka - Shadow (koyu renk)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route_shadow'),
        points: points,
        color: const Color(0xFF1565C0), // Dark Blue
        width: 10,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ),
    );

    // 2. Ana tabaka - Parlak mavi yol
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route_main'),
        points: points,
        color: const Color(0xFF4285F4), // Google Maps Blue
        width: 7,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 2,
      ),
    );

    // 3. Ust tabaka - Beyaz dash pattern
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('active_route_dash'),
        points: points,
        color: Colors.white.withValues(alpha: 0.6),
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        patterns: [
          PatternItem.dash(15),
          PatternItem.gap(10),
        ],
        zIndex: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationProvider>();
    final routeProvider = context.watch<RouteProvider>();
    final routesProvider = context.watch<RoutesProvider>();
    final targetLocation = locationProvider.targetLocation;
    final targetRoute = routesProvider.targetRoute;

    // Konum veya rota degisikliklerini kontrol et ve marker'lari guncelle
    if (_isInitialized && _mapController != null) {
      final currentLocationCount = locationProvider.locations.length;
      final currentRoutePointCount = routeProvider.currentRoutePoints.length;

      if (currentLocationCount != _previousLocationCount ||
          currentRoutePointCount != _previousRoutePointCount) {
        _previousLocationCount = currentLocationCount;
        _previousRoutePointCount = currentRoutePointCount;

        // Marker'lari ve route'u guncelle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateMarkersAndRoute();
          }
        });
      }
    }

    // Hedef konum varsa haritada goster
    if (targetLocation != null &&
        targetLocation.id != _lastFocusedLocationId &&
        _mapController != null &&
        _isInitialized) {
      _lastFocusedLocationId = targetLocation.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(targetLocation.latitude, targetLocation.longitude),
            18,
          ),
        );
        _mapController!.showMarkerInfoWindow(MarkerId(targetLocation.id));
      });
    }

    // Hedef rota varsa haritada goster
    if (targetRoute != null &&
        targetRoute.id != _lastFocusedRouteId &&
        _mapController != null &&
        _isInitialized) {
      _lastFocusedRouteId = targetRoute.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTargetRouteOnMap(targetRoute);
        }
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildRouteControls(),
          _buildRouteInfo(),
          _buildTargetRouteInfo(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Haritayı kullanmak için\nkonum izni gereklidir.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocation,
              child: const Text('İzin Ver ve Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: AppConstants.konyaLocation,
        zoom: AppConstants.defaultZoom,
      ),
      style: isDarkMode ? MapStyles.darkStyle : null,
      onMapCreated: (controller) {
        _mapController = controller;
        _updateMarkersAndRoute();
      },
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onLongPress: _onMapLongPress,
    );
  }

  Widget _buildRouteControls() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Consumer<RouteProvider>(
        builder: (context, provider, child) {
          return Center(
            child: SizedBox(
              width: 200,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _toggleRouteTracking(provider),
                icon: Icon(
                  provider.isTracking ? Icons.stop : Icons.play_arrow,
                  size: 28,
                ),
                label: Text(
                  provider.isTracking ? 'Bitir' : 'Başlat',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isTracking
                      ? AppTheme.error
                      : AppTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Consumer<RouteProvider>(
      builder: (context, provider, child) {
        if (!provider.isTracking) return const SizedBox.shrink();

        return Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(
                        icon: Icons.timer,
                        label: 'Sure',
                        value: provider.formattedDuration,
                      ),
                      _InfoItem(
                        icon: Icons.straighten,
                        label: 'Mesafe',
                        value: provider.formattedCurrentDistance,
                      ),
                      _InfoItem(
                        icon: Icons.location_on,
                        label: 'Noktalar',
                        value: '${provider.currentRoutePoints.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleRouteTracking(RouteProvider provider) async {
    if (provider.isTracking) {
      await showDialog<String>(
        context: context,
        builder: (context) => const RouteNameDialog(),
      );
    } else {
      final success = await provider.startRouteTracking();
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.startTracking),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.locationPermissionRequired),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  void _onMapLongPress(LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddLocationFromMapBottomSheet(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      ),
    );
  }

  // Hedef rotayi haritada profesyonel sekilde goster (Google Maps tarzi)
  void _showTargetRouteOnMap(RouteModel route) {
    debugPrint(
      '🗺️ MapScreen: Target route gösteriliyor - ${route.name}, ${route.points.length} nokta, ${route.formattedDistance}',
    );

    if (route.points.isEmpty) {
      debugPrint('❌ MapScreen: Route points BOŞ! Çizgi çizilemez.');
      return;
    }

    debugPrint('✅ MapScreen: Route çiziliyor...');

    setState(() {
      _markers.clear();
      _polylines.clear();

      final points =
          route.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

      // 1. Alt tabaka - Kalin shadow/border (koyu mavi)
      _polylines.add(
        Polyline(
          polylineId: PolylineId('${route.id}_shadow'),
          points: points,
          color: const Color(0xFF1A237E), // Deep Blue Shadow
          width: 12,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 1,
        ),
      );

      // 2. Ana tabaka - Google Maps mavi yol
      _polylines.add(
        Polyline(
          polylineId: PolylineId('${route.id}_main'),
          points: points,
          color: const Color(0xFF4285F4), // Google Maps Blue
          width: 8,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          zIndex: 2,
        ),
      );

      // 3. Ust tabaka - Beyaz dash pattern (yol uzerindeki cizgiler)
      _polylines.add(
        Polyline(
          polylineId: PolylineId('${route.id}_dash'),
          points: points,
          color: Colors.white.withValues(alpha: 0.5),
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(15),
          ],
          zIndex: 3,
        ),
      );

      // 4. Baslangic marker (Buyuk yesil)
      _markers.add(
        Marker(
          markerId: MarkerId('${route.id}_start'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🚩 Başlangıç',
            snippet:
                '${DateFormat('HH:mm').format(route.startTime)} • ${route.points.length} nokta',
          ),
        ),
      );

      // 5. Bitis marker (Buyuk kirmizi)
      _markers.add(
        Marker(
          markerId: MarkerId('${route.id}_end'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🏁 Bitiş',
            snippet: route.endTime != null
                ? '${DateFormat('HH:mm').format(route.endTime!)} • ${route.formattedDistance}'
                : route.formattedDistance,
          ),
        ),
      );

      // 6. Ara noktalar - Her 15-20 noktada bir kucuk mor marker
      if (points.length > 30) {
        // Sadece uzun rotalarda goster
        final interval = (points.length / 5).ceil(); // ~5 ara nokta
        for (int i = interval; i < points.length - interval; i += interval) {
          _markers.add(
            Marker(
              markerId: MarkerId('${route.id}_waypoint_$i'),
              position: points[i],
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              ),
              alpha: 0.7,
              anchor: const Offset(0.5, 0.5),
              infoWindow: InfoWindow(
                title: 'Nokta ${i + 1}',
                snippet: DateFormat('HH:mm').format(route.points[i].timestamp),
              ),
            ),
          );
        }
      }
    });

    // Kamerayi rotanin tamamini gorecek sekilde ayarla
    _fitRouteBounds(route);
  }

  // Rota bounds'una gore kamera ayarla
  void _fitRouteBounds(RouteModel route) async {
    if (route.points.isEmpty || _mapController == null) return;

    double minLat = route.points.first.latitude;
    double maxLat = route.points.first.latitude;
    double minLng = route.points.first.longitude;
    double maxLng = route.points.first.longitude;

    for (var point in route.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    if (_mapController != null && mounted) {
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }
  }

  // Hedef rota bilgi karti
  Widget _buildTargetRouteInfo() {
    final routesProvider = context.watch<RoutesProvider>();
    final targetRoute = routesProvider.targetRoute;

    if (targetRoute == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baslik
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetRoute.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(targetRoute.startTime),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      routesProvider.clearTargetRoute();
                      // Marker'lari ve polyline'lari temizle
                      setState(() {
                        _markers.clear();
                        _polylines.clear();
                        _lastFocusedRouteId = null;
                      });
                      // Normal marker'lari geri yukle
                      _updateMarkersAndRoute();
                    },
                  ),
                ],
              ),
            ),
            // Istatistikler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _RouteStatItem(
                    icon: Icons.straighten,
                    label: 'Mesafe',
                    value: targetRoute.formattedDistance,
                    color: const Color(0xFF42A5F5),
                  ),
                  _RouteStatItem(
                    icon: Icons.timer,
                    label: 'Süre',
                    value: targetRoute.formattedDuration,
                    color: const Color(0xFFFF7043),
                  ),
                  _RouteStatItem(
                    icon: Icons.location_on,
                    label: 'Noktalar',
                    value: '${targetRoute.points.length}',
                    color: const Color(0xFF66BB6A),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Rota istatistik widget'i
class _RouteStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RouteStatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
