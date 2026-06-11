import '../models/tracking_event.dart';
import '../storage/event_storage_backend.dart';
import '../storage/in_memory_event_storage.dart';

/// Event queue with FIFO ordering backed by pluggable storage.
///
/// Uses [EventStorageBackend] — SQLite in production, in-memory for tests.
class EventQueue {
  final EventStorageBackend _storage;

  EventQueue({EventStorageBackend? storage, int maxSize = 1000})
      : _storage = storage ?? InMemoryEventStorage(maxSize: maxSize);

  /// Add an event to the queue.
  Future<void> enqueue(TrackingEvent event) => _storage.enqueue(event);

  /// Remove and return up to [count] events from the front.
  Future<List<TrackingEvent>> drain(int count) => _storage.drain(count);

  /// Number of events currently queued.
  Future<int> get length => _storage.length;

  /// Whether the queue is empty.
  Future<bool> get isEmpty => _storage.isEmpty;

  /// Delete all events.
  Future<void> deleteAll() => _storage.deleteAll();
}
