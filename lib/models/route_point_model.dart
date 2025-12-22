class RoutePointModel {
  final String id;
  final String routeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  RoutePointModel({
    required this.id,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });

  factory RoutePointModel.fromMap(Map<String, dynamic> map) {
    return RoutePointModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      speed: map['speed'] as double?,
      accuracy: map['accuracy'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  RoutePointModel copyWith({
    String? id,
    String? routeId,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    double? speed,
    double? accuracy,
  }) {
    return RoutePointModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      speed: speed ?? this.speed,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}
