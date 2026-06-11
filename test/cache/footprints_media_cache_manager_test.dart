import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/cache/footprints_media_cache_manager.dart';

void main() {
  group('FootprintsMediaCacheManager.configure', () {
    tearDown(() {
      FootprintsMediaCacheManager.resetForTesting();
    });

    test('is idempotent — repeated calls with different values do not throw',
        () {
      expect(
        () {
          FootprintsMediaCacheManager.configure(
            maxBytes: 50 * 1024 * 1024,
            ttl: const Duration(days: 7),
          );
          FootprintsMediaCacheManager.configure(
            maxBytes: 200 * 1024 * 1024,
            ttl: const Duration(days: 14),
          );
          FootprintsMediaCacheManager.configure(
            maxBytes: 100 * 1024 * 1024,
            ttl: const Duration(days: 10),
          );
        },
        returnsNormally,
      );
    });

    test(
        'resetForTesting allows reconfiguration without constructing the '
        'singleton', () {
      FootprintsMediaCacheManager.configure(
        maxBytes: 10 * 1024 * 1024,
        ttl: const Duration(hours: 1),
      );
      FootprintsMediaCacheManager.resetForTesting();
      // After reset, calling configure again remains a pure in-memory op
      // (no platform IO yet since .instance was never read).
      expect(
        () => FootprintsMediaCacheManager.configure(
          maxBytes: 20 * 1024 * 1024,
          ttl: const Duration(hours: 2),
        ),
        returnsNormally,
      );
    });
  });
}
