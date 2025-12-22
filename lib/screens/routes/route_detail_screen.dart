import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/route_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    if (widget.route.points.isEmpty) return;

    // Rota cizgisini olustur
    final points = widget.route.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId(widget.route.id),
          points: points,
          color: AppTheme.routeCompleted,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );

      // Baslangic marker
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Baslangic'),
        ),
      );

      // Bitis marker
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Bitis'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Detayi'),
      ),
      body: Column(
        children: [
          // Rota bilgileri
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.route.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(widget.route.startTime),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailStatItem(
                      icon: Icons.straighten,
                      label: 'Mesafe',
                      value: widget.route.formattedDistance,
                      color: AppTheme.primaryColor,
                    ),
                    _DetailStatItem(
                      icon: Icons.timer,
                      label: 'Sure',
                      value: widget.route.formattedDuration,
                      color: AppTheme.accent,
                    ),
                    _DetailStatItem(
                      icon: Icons.location_on,
                      label: 'Noktalar',
                      value: '${widget.route.points.length}',
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Harita
          Expanded(
            child: widget.route.points.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text('Bu rotada kayitli nokta bulunamadi'),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.route.points.first.latitude,
                        widget.route.points.first.longitude,
                      ),
                      zoom: AppConstants.routeZoom,
                    ),
                    polylines: _polylines,
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _fitRouteInView();
                    },
                    mapType: MapType.normal,
                    compassEnabled: true,
                    zoomControlsEnabled: true,
                  ),
          ),
        ],
      ),
    );
  }

  void _fitRouteInView() async {
    if (_mapController == null || widget.route.points.isEmpty) return;

    // Calculate bounds
    double minLat = widget.route.points.first.latitude;
    double maxLat = widget.route.points.first.latitude;
    double minLng = widget.route.points.first.longitude;
    double maxLng = widget.route.points.first.longitude;

    for (var point in widget.route.points) {
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
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _DetailStatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailStatItem({
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
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
