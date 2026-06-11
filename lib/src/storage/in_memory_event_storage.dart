import 'dart:collection';

import '../models/tracking_event.dart';
import 'event_storage_backend.dart';

/// In-memory implementation of [EventStorageBackend] for testing.
class InMemoryEventStorage implements EventStorageBackend {
  final Queue<TrackingEvent> _queue = Queue<TrackingEvent>();
  final int maxSize;

  InMemoryEventStorage({this.maxSize = 1000});

  @override
  Future<void> enqueue(TrackingEvent event) async {
    if (_queue.length >= maxSize) {
      _queue.removeFirst();
    }
    _queue.addLast(event);
  }

  @override
  Future<List<TrackingEvent>> drain(int count) async {
    final events = <TrackingEvent>[];
    while (events.length < count && _queue.isNotEmpty) {
      events.add(_queue.removeFirst());
    }
    return events;
  }

  @override
  Future<int> get length async => _queue.length;

  @override
  Future<bool> get isEmpty async => _queue.isEmpty;

  @override
  Future<void> deleteAll() async {
    _queue.clear();
  }
}
