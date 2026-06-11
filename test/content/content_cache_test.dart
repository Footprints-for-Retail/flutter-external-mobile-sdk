import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/content/content_cache.dart';
import 'package:footprints_sdk/src/models/content_delivery_response.dart';
import 'package:footprints_sdk/src/storage/in_memory_content_storage.dart';

void main() {
  group('ContentCache', () {
    late ContentCache cache;

    setUp(() {
      cache = ContentCache(storage: InMemoryContentStorage());
    });

    test('returns null for empty cache', () async {
      expect(await cache.get('home'), isNull);
    });

    test('stores and retrieves response', () async {
      const response = ContentDeliveryResponse(success: true);
      await cache.put('home', response);

      final cached = await cache.get('home');
      expect(cached, isNotNull);
      expect(cached!.success, isTrue);
    });

    test('returns null after TTL expires', () async {
      const response = ContentDeliveryResponse(success: true);
      await cache.put('home', response, ttl: const Duration(milliseconds: 50));

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(await cache.get('home'), isNull);
    });

    test('clear removes all entries', () async {
      const response = ContentDeliveryResponse(success: true);
      await cache.put('home', response);
      await cache.put('detail', response);

      await cache.clear();
      expect(await cache.get('home'), isNull);
      expect(await cache.get('detail'), isNull);
    });
  });
}
