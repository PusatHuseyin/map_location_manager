class LocationModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final DateTime createdAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    required this.createdAt,
  });

  // Database'den model olustur
  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Model'i database'e kaydet
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LocationModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? createdAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
