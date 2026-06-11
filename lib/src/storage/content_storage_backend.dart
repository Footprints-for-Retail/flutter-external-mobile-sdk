import '../models/content_delivery_response.dart';

/// Abstract interface for content cache storage.
///
/// Production uses [SqliteContentStorage], tests use [InMemoryContentStorage].
abstract class ContentStorageBackend {
  Future<ContentDeliveryResponse?> get(String key);
  Future<void> put(String key, ContentDeliveryResponse response, Duration ttl);
  Future<void> clear();
}
