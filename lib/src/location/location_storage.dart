import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite-backed local persistence for location history.
///
/// Matches Android SDK's Room-based LocationEntity storage.
/// Stores latitude, longitude, accuracy, altitude, heading, speed, timestamp.
class LocationStorage {
  static const _tableName = 'location_history';
  static const _dbName = 'footprints_location.db';

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            is_precise INTEGER NOT NULL DEFAULT 0,
            altitude REAL NOT NULL DEFAULT 0,
            heading REAL NOT NULL DEFAULT 0,
            speed REAL NOT NULL DEFAULT 0,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  /// Insert a position into the location history.
  Future<void> insert(Position position) async {
    final db = await _database;
    await db.insert(_tableName, {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'is_precise': position.accuracy < 5 ? 1 : 0,
      'altitude': position.altitude,
      'heading': position.heading,
      'speed': position.speed,
      'timestamp': position.timestamp.millisecondsSinceEpoch,
    });
  }

  /// Get all stored locations, newest first.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _database;
    return db.query(_tableName, orderBy: 'id DESC');
  }

  /// Get the most recent stored location.
  Future<Map<String, dynamic>?> getLatest() async {
    final db = await _database;
    final rows = await db.query(
      _tableName,
      orderBy: 'id DESC',
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Delete all stored locations.
  Future<void> deleteAll() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  /// Close the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
