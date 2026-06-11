import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/content_delivery_response.dart';
import 'content_storage_backend.dart';

/// SQLite-backed implementation of [ContentStorageBackend].
///
/// Cached content persists across app restarts with TTL expiration.
class SqliteContentStorage implements ContentStorageBackend {
  static const _tableName = 'content_cache';
  static const _dbName = 'footprints_cache.db';

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
            cache_key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            expires_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<ContentDeliveryResponse?> get(String key) async {
    final db = await _database;
    final rows = await db.query(
      _tableName,
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final expiresAt = DateTime.parse(row['expires_at'] as String);

    if (DateTime.now().isAfter(expiresAt)) {
      await db.delete(_tableName, where: 'cache_key = ?', whereArgs: [key]);
      return null;
    }

    final json = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
    return ContentDeliveryResponse.fromJson(json);
  }

  @override
  Future<void> put(
    String key,
    ContentDeliveryResponse response,
    Duration ttl,
  ) async {
    final db = await _database;
    await db.insert(
      _tableName,
      {
        'cache_key': key,
        'payload': jsonEncode(response.toJson()),
        'expires_at': DateTime.now().add(ttl).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clear() async {
    final db = await _database;
    await db.delete(_tableName);
  }

  /// Close the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
