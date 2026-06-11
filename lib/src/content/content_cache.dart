import '../models/content_delivery_response.dart';
import '../storage/content_storage_backend.dart';
import '../storage/in_memory_content_storage.dart';

/// TTL cache for content delivery responses backed by pluggable storage.
///
/// Uses [ContentStorageBackend] — SQLite in production, in-memory for tests.
class ContentCache {
  final ContentStorageBackend _storage;

  ContentCache({ContentStorageBackend? storage})
      : _storage = storage ?? InMemoryContentStorage();

  /// Get cached response if within TTL.
  Future<ContentDeliveryResponse?> get(String? key) {
    return _storage.get(key ?? '_default');
  }

  /// Store response with TTL.
  Future<void> put(
    String? key,
    ContentDeliveryResponse response, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    return _storage.put(key ?? '_default', response, ttl);
  }

  /// Clear all cached entries.
  Future<void> clear() => _storage.clear();
}
