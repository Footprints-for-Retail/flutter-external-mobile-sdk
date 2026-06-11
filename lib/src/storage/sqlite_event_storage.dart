import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tracking_event.dart';
import 'event_storage_backend.dart';

/// SQLite-backed implementation of [EventStorageBackend].
///
/// Events persist across app restarts. FIFO ordering via auto-increment ID.
class SqliteEventStorage implements EventStorageBackend {
  static const _tableName = 'event_queue';
  static const _dbName = 'footprints_events.db';

  final int maxSize;
  Database? _db;

  SqliteEventStorage({this.maxSize = 1000});

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
            payload TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> enqueue(TrackingEvent event) async {
    final db = await _database;
    await db.insert(_tableName, {
      'payload': jsonEncode(event.toJson()),
      'created_at': DateTime.now().toIso8601String(),
    });

    // Enforce max size — delete oldest if over limit
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
    ) ?? 0;

    if (count > maxSize) {
      final excess = count - maxSize;
      await db.rawDelete(
        '''
        DELETE FROM $_tableName WHERE id IN (
          SELECT id FROM $_tableName ORDER BY id ASC LIMIT ?
        )
        ''',
        [excess],
      );
    }
  }

  @override
  Future<List<TrackingEvent>> drain(int count) async {
    final db = await _database;
    final rows = await db.query(
      _tableName,
      orderBy: 'id ASC',
      limit: count,
    );

    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['id'] as int).toList();
    await db.delete(
      _tableName,
      where: 'id IN (${ids.join(',')})',
    );

    return rows.map((r) {
      final json = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
      return TrackingEvent.fromJson(json);
    }).toList();
  }

  @override
  Future<int> get length async {
    final db = await _database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
    ) ?? 0;
  }

  @override
  Future<bool> get isEmpty async => (await length) == 0;

  @override
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
