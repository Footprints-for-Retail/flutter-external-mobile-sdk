import '../models/content_delivery_response.dart';
import 'content_storage_backend.dart';

/// In-memory implementation of [ContentStorageBackend] for testing.
class InMemoryContentStorage implements ContentStorageBackend {
  final Map<String, _CacheEntry> _entries = {};

  @override
  Future<ContentDeliveryResponse?> get(String key) async {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.response;
  }

  @override
  Future<void> put(
    String key,
    ContentDeliveryResponse response,
    Duration ttl,
  ) async {
    _entries[key] = _CacheEntry(
      response: response,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

class _CacheEntry {
  final ContentDeliveryResponse response;
  final DateTime expiresAt;

  _CacheEntry({required this.response, required this.expiresAt});
}
