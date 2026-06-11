import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/content/rotation_selector.dart';
import 'package:footprints_sdk/src/models/ad_content.dart';
import 'package:footprints_sdk/src/storage/in_memory_rotation_storage.dart';

AdContent _ad(String id) => AdContent(adId: id);

void main() {
  group('RotationSelector — roundRobin', () {
    late RotationSelector selector;

    setUp(() {
      selector = RotationSelector(
        storage: InMemoryRotationStorage(),
      );
    });

    test('returns null for empty list', () async {
      expect(await selector.pick([], rotationKey: 'k'), isNull);
    });

    test('returns single ad without rotation', () async {
      final ad = _ad('a1');
      expect(
        (await selector.pick([ad], rotationKey: 'k'))?.adId,
        'a1',
      );
    });

    test('cycles through ads in order', () async {
      final ads = [_ad('a1'), _ad('a2'), _ad('a3')];
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a1');
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a2');
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a3');
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a1');
    });

    test('handles ad that disappeared from list', () async {
      await selector.pick(
        [_ad('a1'), _ad('a2')],
        rotationKey: 'k',
      ); // cursor → a1

      // a1 is gone; selector should start from beginning of new list.
      expect(
        (await selector.pick([_ad('a2'), _ad('a3')], rotationKey: 'k'))?.adId,
        'a2',
      );
    });

    test('different keys rotate independently', () async {
      final ads = [_ad('a1'), _ad('a2')];
      expect((await selector.pick(ads, rotationKey: 'k1'))?.adId, 'a1');
      expect((await selector.pick(ads, rotationKey: 'k2'))?.adId, 'a1');
      expect((await selector.pick(ads, rotationKey: 'k1'))?.adId, 'a2');
    });
  });

  group('RotationSelector — none', () {
    test('always returns first candidate', () async {
      final selector = RotationSelector(
        storage: InMemoryRotationStorage(),
        strategy: RotationStrategy.none,
      );
      final ads = [_ad('a1'), _ad('a2'), _ad('a3')];
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a1');
      expect((await selector.pick(ads, rotationKey: 'k'))?.adId, 'a1');
    });
  });

  group('RotationSelector — random', () {
    test('returns something from the list', () async {
      final selector = RotationSelector(
        storage: InMemoryRotationStorage(),
        strategy: RotationStrategy.random,
      );
      final ads = [_ad('a1'), _ad('a2'), _ad('a3')];
      for (var i = 0; i < 20; i++) {
        final picked = await selector.pick(ads, rotationKey: 'k');
        expect(['a1', 'a2', 'a3'].contains(picked?.adId), isTrue);
      }
    });
  });
}
