import '../models/tracking_event.dart';

/// Abstract interface for event queue storage.
///
/// Production uses [SqliteEventStorage], tests use [InMemoryEventStorage].
abstract class EventStorageBackend {
  Future<void> enqueue(TrackingEvent event);
  Future<List<TrackingEvent>> drain(int count);
  Future<int> get length;
  Future<bool> get isEmpty;
  Future<void> deleteAll();
}
