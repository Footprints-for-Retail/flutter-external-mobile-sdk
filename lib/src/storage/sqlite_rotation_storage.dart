import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'rotation_storage_backend.dart';

/// SQLite-backed implementation of [RotationStorageBackend].
///
/// Rotation cursors persist across app restarts so users continue seeing
/// a fair distribution of creatives over time.
class SqliteRotationStorage implements RotationStorageBackend {
  static const _tableName = 'rotation_cursors';
  static const _dbName = 'footprints_rotation.db';

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
            cursor_key TEXT PRIMARY KEY,
            last_shown_ad_id TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<String?> getLastShownAdId(String rotationKey) async {
    final db = await _database;
    final rows = await db.query(
      _tableName,
      columns: ['last_shown_ad_id'],
      where: 'cursor_key = ?',
      whereArgs: [rotationKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['last_shown_ad_id'] as String?;
  }

  @override
  Future<void> setLastShownAdId(String rotationKey, String adId) async {
    final db = await _database;
    await db.insert(
      _tableName,
      {
        'cursor_key': rotationKey,
        'last_shown_ad_id': adId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
