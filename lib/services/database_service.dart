import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/location_model.dart';
import '../models/route_model.dart';
import '../models/route_point_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'map_location_manager.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE locations (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_distance REAL,
        duration INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE route_points (
        id TEXT PRIMARY KEY,
        route_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        speed REAL,
        accuracy REAL,
        FOREIGN KEY (route_id) REFERENCES routes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_route_points_route_id ON route_points(route_id)',
    );
  }

  Future<int> insertLocation(LocationModel location) async {
    final db = await database;
    return await db.insert(
      'locations',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LocationModel>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => LocationModel.fromMap(maps[i]));
  }

  Future<LocationModel?> getLocation(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'locations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocationModel.fromMap(maps.first);
  }

  Future<int> updateLocation(LocationModel location) async {
    final db = await database;
    return await db.update(
      'locations',
      location.toMap(),
      where: 'id = ?',
      whereArgs: [location.id],
    );
  }

  Future<int> deleteLocation(String id) async {
    final db = await database;
    return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRoute(RouteModel route) async {
    final db = await database;
    return await db.insert(
      'routes',
      route.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RouteModel>> getAllRoutes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      orderBy: 'start_time DESC',
    );

    List<RouteModel> routes = [];
    for (var map in maps) {
      final points = await getRoutePoints(map['id'] as String);
      routes.add(RouteModel.fromMap(map, points: points));
    }

    return routes;
  }

  Future<RouteModel?> getRoute(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final points = await getRoutePoints(id);
    return RouteModel.fromMap(maps.first, points: points);
  }

  Future<RouteModel?> getActiveRoute() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'routes',
      where: 'end_time IS NULL',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final id = maps.first['id'] as String;
    final points = await getRoutePoints(id);
    return RouteModel.fromMap(maps.first, points: points);
  }

  Future<int> updateRoute(RouteModel route) async {
    final db = await database;
    return await db.update(
      'routes',
      route.toMap(),
      where: 'id = ?',
      whereArgs: [route.id],
    );
  }

  Future<int> deleteRoute(String id) async {
    final db = await database;

    return await db.delete('routes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertRoutePoint(RoutePointModel point) async {
    final db = await database;
    return await db.insert(
      'route_points',
      point.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RoutePointModel>> getRoutePoints(String routeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'route_points',
      where: 'route_id = ?',
      whereArgs: [routeId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => RoutePointModel.fromMap(maps[i]));
  }

  Future<int> deleteRoutePoints(String routeId) async {
    final db = await database;
    return await db.delete(
      'route_points',
      where: 'route_id = ?',
      whereArgs: [routeId],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('locations');
    await db.delete('routes');
    await db.delete('route_points');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
