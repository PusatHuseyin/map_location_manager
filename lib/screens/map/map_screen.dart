import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_strings.dart';
import '../../providers/location_provider.dart';
import '../../providers/route_provider.dart';
import '../../models/location_model.dart';
import '../../widgets/add_location_from_map_dialog.dart'; // Actually BottomSheet
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

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final locationProvider = context.read<LocationProvider>();
    final hasPermission = await locationProvider.checkPermissions();

    if (hasPermission && mounted) {
      setState(() => _isInitialized = true);
      _updateMarkersAndRoute();
    }
  }

  void _updateMarkersAndRoute() {
    if (!mounted) return;

    final locationProvider = context.read<LocationProvider>();
    final routeProvider = context.read<RouteProvider>();

    setState(() {
      _markers.clear();
      _polylines.clear();

      // Kaydedilmis konumlari marker olarak ekle
      for (var location in locationProvider.locations) {
        _markers.add(_createLocationMarker(location));
      }

      // Mevcut konumu marker olarak ekle
      if (locationProvider.currentPosition != null) {
        _markers.add(_createCurrentLocationMarker(locationProvider));
      }

      // Aktif rota varsa ciz
      if (routeProvider.isTracking &&
          routeProvider.currentRoutePoints.isNotEmpty) {
        _polylines.add(_createActiveRoutePolyline(routeProvider));
      }
    });
  }

  Marker _createLocationMarker(LocationModel location) {
    return Marker(
      markerId: MarkerId(location.id),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      infoWindow: InfoWindow(
        title: location.name,
        snippet: location.description,
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

  Polyline _createActiveRoutePolyline(RouteProvider provider) {
    final points = provider.currentRoutePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return Polyline(
      polylineId: const PolylineId('active_route'),
      points: points,
      color: AppTheme.routeActive,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildMap(), _buildRouteControls(), _buildRouteInfo()],
      ),
    );
  }

  Widget _buildMap() {
    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Konum izinleri kontrol ediliyor...'),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: AppConstants.konyaLocation,
        zoom: AppConstants.defaultZoom,
      ),
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
      // Show route name dialog
      await showDialog<String>(
        context: context,
        builder: (context) => const RouteNameDialog(),
      );
      // Dialog handles the stop tracking
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
