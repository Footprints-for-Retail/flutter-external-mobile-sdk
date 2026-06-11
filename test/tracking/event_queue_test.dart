import 'package:flutter_test/flutter_test.dart';
import 'package:footprints_sdk/src/models/tracking_event.dart';
import 'package:footprints_sdk/src/storage/in_memory_event_storage.dart';
import 'package:footprints_sdk/src/tracking/event_queue.dart';

void main() {
  group('EventQueue', () {
    late EventQueue queue;

    setUp(() {
      queue = EventQueue(
        storage: InMemoryEventStorage(maxSize: 5),
      );
    });

    test('enqueue and drain', () async {
      await queue.enqueue(const TrackingEvent(
        appkey: 'k',
        mid: 'm',
        requestType: 'reach',
      ),);
      await queue.enqueue(const TrackingEvent(
        appkey: 'k',
        mid: 'm',
        requestType: 'impression',
      ),);

      expect(await queue.length, 2);

      final events = await queue.drain(10);
      expect(events, hasLength(2));
      expect(events[0].requestType, 'reach');
      expect(events[1].requestType, 'impression');
      expect(await queue.isEmpty, isTrue);
    });

    test('drain respects count limit', () async {
      for (var i = 0; i < 4; i++) {
        await queue.enqueue(TrackingEvent(
          appkey: 'k',
          mid: 'm',
          requestType: 'event_$i',
        ),);
      }

      final events = await queue.drain(2);
      expect(events, hasLength(2));
      expect(await queue.length, 2);
    });

    test('discards oldest when maxSize exceeded', () async {
      for (var i = 0; i < 7; i++) {
        await queue.enqueue(TrackingEvent(
          appkey: 'k',
          mid: 'm',
          requestType: 'event_$i',
        ),);
      }

      expect(await queue.length, 5);
      final events = await queue.drain(5);
      expect(events.first.requestType, 'event_2');
    });
  });
}
