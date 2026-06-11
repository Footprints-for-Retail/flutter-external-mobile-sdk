import 'content_storage_backend.dart';
import 'event_storage_backend.dart';
import 'in_memory_content_storage.dart';
import 'in_memory_event_storage.dart';
import 'in_memory_rotation_storage.dart';
import 'rotation_storage_backend.dart';
import 'sqlite_content_storage.dart';
import 'sqlite_event_storage.dart';
import 'sqlite_rotation_storage.dart';

/// Manages database initialization and provides storage backends.
///
/// Use [forProduction] for real apps (SQLite) or [forTesting] for tests
/// (in-memory).
class DatabaseManager {
  final EventStorageBackend eventStorage;
  final ContentStorageBackend contentStorage;
  final RotationStorageBackend rotationStorage;

  DatabaseManager._({
    required this.eventStorage,
    required this.contentStorage,
    required this.rotationStorage,
  });

  /// Create a production database manager with SQLite backends.
  factory DatabaseManager.forProduction({int maxEventQueueSize = 1000}) {
    return DatabaseManager._(
      eventStorage: SqliteEventStorage(maxSize: maxEventQueueSize),
      contentStorage: SqliteContentStorage(),
      rotationStorage: SqliteRotationStorage(),
    );
  }

  /// Create a testing database manager with in-memory backends.
  factory DatabaseManager.forTesting({int maxEventQueueSize = 1000}) {
    return DatabaseManager._(
      eventStorage: InMemoryEventStorage(maxSize: maxEventQueueSize),
      contentStorage: InMemoryContentStorage(),
      rotationStorage: InMemoryRotationStorage(),
    );
  }

  /// Close all database connections.
  Future<void> close() async {
    if (eventStorage is SqliteEventStorage) {
      await (eventStorage as SqliteEventStorage).close();
    }
    if (contentStorage is SqliteContentStorage) {
      await (contentStorage as SqliteContentStorage).close();
    }
    if (rotationStorage is SqliteRotationStorage) {
      await (rotationStorage as SqliteRotationStorage).close();
    }
  }
}
