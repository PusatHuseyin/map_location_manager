import 'route_point_model.dart';

class RouteModel {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final double? totalDistance;
  final int? duration;
  final List<RoutePointModel> points;

  RouteModel({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.totalDistance,
    this.duration,
    this.points = const [],
  });

  bool get isActive => endTime == null;

  // Database model
  factory RouteModel.fromMap(
    Map<String, dynamic> map, {
    List<RoutePointModel>? points,
  }) {
    return RouteModel(
      id: map['id'] as String,
      name: map['name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      totalDistance: map['total_distance'] as double?,
      duration: map['duration'] as int?,
      points: points ?? [],
    );
  }

  // Model'i database'e kaydet
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_distance': totalDistance,
      'duration': duration,
    };
  }

  RouteModel copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistance,
    int? duration,
    List<RoutePointModel>? points,
  }) {
    return RouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistance: totalDistance ?? this.totalDistance,
      duration: duration ?? this.duration,
      points: points ?? this.points,
    );
  }

  String get formattedDuration {
    if (duration == null) return '--:--';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    }
    return '${minutes}dk ${seconds}sn';
  }

  String get formattedDistance {
    if (totalDistance == null) return '0 m';
    if (totalDistance! > 999) {
      return '${(totalDistance! / 1000).toStringAsFixed(2)} km';
    }
    return '${totalDistance!.toStringAsFixed(0)} m';
  }
}
